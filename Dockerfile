# We're built on the official Jupyter image for PySpark notebooks
FROM jupyter/pyspark-notebook:latest

# But if it all breaks, blame us instead
MAINTAINER The ThreatHunting Project <project@threathunting.net>

# Set user to run these commands as root
USER root

# Update the list of packages so we can install what we need
RUN apt-get update --yes

# Switch back to the jovyan user to do module installs or this will fail
# due to directory ownership on the cache
USER $NB_USER

# Install the standard Jupyter notebook extensions
RUN conda install jupyter_contrib_nbextensions

# Install Plot.ly for most visualization needs
RUN conda install -y plotly
RUN conda install -y --name python2 plotly

# Elasticsearch client for Python.  The DSL (high level) version also installs
# the standard elasticsearch-py library as a dependency, so it's available
# even though we don't explicity install it here.
RUN conda install -y  elasticsearch-dsl
RUN conda install -y --name python2  elasticsearch-dsl

# Grab the Splunk SDK as well.  Note that this seems to only support
# python2.  Also, it's not in the conda channel, so we have to use
# pip.
RUN pip2 install splunk-sdk

# The first time you 'import plotly' on a new system, it has to build the
# font cache.  This takes a while and also causes spurious warnings, so
# we can just do that during the build process and the user never has to
# see it.
RUN /bin/bash -c 'source /opt/conda/bin/activate && echo 'import plotly' | python -'
RUN /bin/bash -c 'source /opt/conda/envs/python2/bin/activate && echo 'import plotly' | python -'

# Set the notebook default password
ADD passwd-helper.py /tmp
ARG JUPYTER_NB_PASS
RUN JUPYTER_NB_PASS=${JUPYTER_NB_PASS}  python /tmp/passwd-helper.py >> /home/jovyan/.jupyter/jupyter_notebook_config.py

# Add "/home/jovyan/work/lib" to the PYTHONPATH.  Since "/home/jovyan/work"
# is typically a mounted volume, this gives the user a convenient place to
# drop their own Python modules that will be available in all notebooks.
ENV PYTHONPATH "/home/jovyan/work/lib:$PYTHONPATH"
