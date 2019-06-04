# We're built on the official Python 3 "slim" image
FROM debian:stable-slim as hunterbase

# But if it all breaks, blame us instead
LABEL maintainer="The ThreatHunting Project <project@threathunting.net>"

# Set the defaults for the notebook user & group
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

ENV NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    CONDA_PARENT_DIR=/opt \
    HOME=/home/${NB_USER} \
    NODE_INSTALL_URL=https://deb.nodesource.com/setup_10.x \
    CONDA_INSTALL_URL=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

ENV CONDA_DIR=${CONDA_PARENT_DIR}/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}

# Set user to run these commands as root
USER root

# Package updates and installs.  Make sure we're in non-interactive mode!
ENV DEBIAN_FRONTEND noninteractive
ENV INSTALL_PACKAGES bzip2 \
                     ca-certificates \
                     curl \
                     fonts-liberation \
                     gnupg \
                     locales \
                     software-properties-common \
                     sudo \
                     texlive-xetex \
                     wget

RUN apt-get update && apt-get upgrade -y && apt-get install -y ${INSTALL_PACKAGES}

# Create the jovyan user.  This is based heavily on the original Dockerfile
# from the Jupyter project, since we want to remain compatible
RUN groupadd wheel -g 11 && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER

# Set up the 'work' dir
RUN mkdir /home/${NB_USER}/work && \
    chown ${NB_USER}:${NB_GID} /home/${NB_USER}/work

# Install nodejs
RUN curl -sL ${NODE_INSTALL_URL} | bash - && \
    apt-get install -y nodejs

# Prepare for the conda installation. Conda seems to want to create tmp files at the same 
# level as CONDA_DIR (e.g., '/tmp/condac0fj4ty'), so we need to make sure the jovyan
# user can also write there.
RUN mkdir -p ${CONDA_DIR} && \
    chown ${NB_USER} ${CONDA_DIR} && \
    chgrp ${NB_GID} ${CONDA_DIR} && \
    chgrp ${NB_GID} ${CONDA_PARENT_DIR} && \
    chmod g+rwx ${CONDA_PARENT_DIR}

USER ${NB_USER}

# Install miniconda
RUN cd /tmp && \
    wget --quiet ${CONDA_INSTALL_URL} && \
    /bin/bash Miniconda3-latest-Linux-x86_64.sh -b -f -p ${CONDA_DIR} && \
    conda config --system --prepend channels conda-forge && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    conda install --quiet --yes conda && \
    conda update --all --quiet --yes && \
    conda clean -tipsy

# Install Tini
RUN conda install tini

# Install Jupyter
RUN conda install notebook jupyterhub jupyterlab

# Configure Jupyter
RUN jupyter labextension install @jupyterlab/hub-extension@^0.12.0 && \
    npm cache clean --force

RUN jupyter notebook --generate-config


# Start notebook server at boot
USER root
RUN echo $PATH
EXPOSE 8888
WORKDIR ${HOME}

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY docker-stacks/base-notebook/start.sh /usr/local/bin/
COPY docker-stacks/base-notebook/start-notebook.sh /usr/local/bin/
COPY docker-stacks/base-notebook/start-singleuser.sh /usr/local/bin/
COPY docker-stacks/base-notebook/jupyter_notebook_config.py /etc/jupyter/

# Clean up our install caches
RUN rm -rf /home/${NB_USER}/.cache

# Switch back to the notebook user as the default user
USER ${NB_USER}


###############################################################################
FROM hunterbase as hunter

LABEL maintainer="The ThreatHunting Project <project@threathunting.net>"

ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}

# OS Packages we need
ENV INSTALL_PACKAGES ffmpeg

# Install Python packages.
ENV INSTALL_PACKAGES_CONDA beautifulsoup4 \
                           bokeh \
                           elasticsearch-dsl \
                           ipywidgets \
                           matplotlib \
                           networkx \
                           olefile \
                           pandas \
                           plotly \
                           scikit-image \
                           scikit-learn \
                           scipy \
                           seaborn \
                           sqlalchemy \
                           statsmodels \
                           tqdm \
                           xlrd

ENV INSTALL_PACKAGES_PIP cufflinks \
                         huntlib \
                         splunk-sdk

# Add required OS packages
USER root
RUN apt-get update && \
    apt-get install -y ${INSTALL_PACKAGES}

# Switch back to the jovyan user to do module installs or this will fail
# due to directory ownership on the cache
USER $NB_USER

RUN conda install -y jupyter_contrib_nbextensions ${INSTALL_PACKAGES_CONDA} && \
    pip install --upgrade ${INSTALL_PACKAGES_PIP} && \
    conda remove --quiet --yes --force qt pyqt && \
    conda clean -tipsy

# Set up some Jupyter Notebook extensions
RUN jupyter nbextension enable toc2/main && \
  jupyter nbextension enable execute_time/ExecuteTime && \
  jupyter nbextension enable python-markdown/main && \
  jupyter nbextension enable --py widgetsnbextension --sys-prefix

# Set up some useful Jupyter Lab extensions
RUN jupyter labextension install @jupyterlab/plotly-extension \
                                 @jupyterlab/toc \
                                 @jupyter-widgets/jupyterlab-manager@^0.38.1 \
                                 jupyterlab_bokeh@0.6.3 && \
    npm cache clean --force && \
    rm -rf ${CONDA_DIR}/share/jupyter/lab/staging && \
    rm -rf /home/${NB_USER}/.cache/yarn && \
    rm -rf /home/${NB_USER}/.node-gyp

# The first time you 'import plotly' on a new system, it has to build the
# font cache.  This takes a while and also causes spurious warnings, so
# we can just do that during the build process and the user never has to
# see it.
RUN python -c 'import plotly'

# Set the notebook default password
ADD passwd-helper.py /tmp
ARG JUPYTER_NB_PASS
RUN mkdir -p /home/jovyan/.jupyter ; JUPYTER_NB_PASS=${JUPYTER_NB_PASS}  python /tmp/passwd-helper.py >> /home/jovyan/.jupyter/jupyter_notebook_config.py

# Add "/home/jovyan/work/lib" to the PYTHONPATH.  Since "/home/jovyan/work"
# is typically a mounted volume, this gives the user a convenient place to
# drop their own Python modules that will be available in all notebooks.
ENV PYTHONPATH "/home/jovyan/work/lib:$PYTHONPATH"

###############################################################################
# Most of this section is cribbed directly from the Jupyter project's
# Dockerfile for their pyspark notebook.  The original is available at:
# https://github.com/jupyter/docker-stacks/blob/master/pyspark-notebook/Dockerfile
#
# Any errors are my own, I'm sure.
#
FROM hunter as sparkhunter

LABEL maintainer="The ThreatHunting Project <project@threathunting.net>"

# Do the entire thing as root
USER root

ENV NB_USER=jovyan \
    CONDA_DIR=/opt/conda \
    SPARK_VERSION=2.4.3 \
    HADOOP_VERSION=2.7

ENV PATH=${CONDA_DIR}/bin:${PATH}

ENV SPARK_HOME /usr/local/spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip
ENV MESOS_NATIVE_LIBRARY /usr/local/lib/libmesos.so
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info

# OS Packages we need
ENV INSTALL_PACKAGES openjdk-8-jre-headless ca-certificates-java

# Install Python packages.
ENV INSTALL_PACKAGES_CONDA pyarrow

# Add required OS packages
RUN apt-get update && \
    mkdir -p /usr/share/man/man1 && \
    apt-get install -y ${INSTALL_PACKAGES}

RUN cd /tmp && \
        wget -q https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
        tar xzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local --owner root --group root --no-same-owner && \
        rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN cd /usr/local && ln -s spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark

# Mesos dependencies
# Install from the Xenial Mesosphere repository since there does not (yet)
# exist a Bionic repository and the dependencies seem to be compatible for now.
COPY docker-stacks/pyspark-notebook/mesos.key /tmp/
RUN apt-get -y update && \
    apt-get install --no-install-recommends -y gnupg && \
    apt-key add /tmp/mesos.key && \
    echo "deb http://repos.mesosphere.io/ubuntu xenial main" > /etc/apt/sources.list.d/mesosphere.list && \
    apt-get -y update && \
    apt-get --no-install-recommends -y install mesos=1.2\* && \
    apt-get purge --auto-remove -y gnupg

# Instal python modules
RUN conda install -y ${INSTALL_PACKAGES_CONDA} && \
    conda clean -tipsy

# Set the default user again so we don't accidentally run as root
USER ${NB_USER}
