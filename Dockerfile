# We're built on the official Jupyter image for PySpark notebooks
FROM jupyter/pyspark-notebook:latest

# But if it all breaks, blame us instead
MAINTAINER The ThreatHunting Project <project@threathunting.net>

# Set user to run these commands as root
USER root

# Switch back to the jovyan user to do module installs or this will fail
# due to directory ownership on the cache
USER $NB_USER

# Update anaconda to latest version, create a python2 environment
RUN conda update -y -n base conda && conda create --name python2 python=2

# Install the Python 2.x kernel
RUN /opt/conda/envs/python2/bin/pip install ipykernel && /opt/conda/envs/python2/bin/python -m ipykernel install --user

# Install Python packages.
ENV INSTALL_PACKAGES_CONDA plotly<3.0 elasticsearch-dsl seaborn scikit-learn ipywidgets cufflinks-py
ENV INSTALL_PACKAGES_PIP splunk-sdk featuretools

RUN conda install -y jupyter_contrib_nbextensions ${INSTALL_PACKAGES_CONDA} && \
    conda install -y --name python2 ${INSTALL_PACKAGES_CONDA} && \
    pip install ${INSTALL_PACKAGES_PIP} && \
    /opt/conda/envs/python2/bin/pip install ${INSTALL_PACKAGES_PIP}

# The first time you 'import plotly' on a new system, it has to build the
# font cache.  This takes a while and also causes spurious warnings, so
# we can just do that during the build process and the user never has to
# see it.
RUN /opt/conda/bin/python -c 'import plotly' && /opt/conda/envs/python2/bin/python -c 'import plotly'

# Set the notebook default password
ADD passwd-helper.py /tmp
ARG JUPYTER_NB_PASS
RUN mkdir -p /home/jovyan/.jupyter ; JUPYTER_NB_PASS=${JUPYTER_NB_PASS}  python /tmp/passwd-helper.py >> /home/jovyan/.jupyter/jupyter_notebook_config.py

# Add "/home/jovyan/work/lib" to the PYTHONPATH.  Since "/home/jovyan/work"
# is typically a mounted volume, this gives the user a convenient place to
# drop their own Python modules that will be available in all notebooks.
ENV PYTHONPATH "/home/jovyan/work/lib:$PYTHONPATH"
