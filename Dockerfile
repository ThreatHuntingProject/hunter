# We're built on the official Jupyter image for PySpark notebooks
FROM jupyter/pyspark-notebook

# But if it all breaks, blame us instead
MAINTAINER The ThreatHunting Project <project@threathunting.net>

# Set user to run these commands as root
USER root

# Update the list of packages so we can install what we need
RUN apt-get update --yes

# Install pip and the pieces necessary to build Python modules
RUN apt-get install --yes python-pip
RUN apt-get install --yes python-dev
RUN apt-get install --yes build-essential

# While we are still root, install some packages we need as prereqs for
# python modules later
# matplotlib prereqs
RUN apt-get install --yes libfreetype6-dev
RUN apt-get install --yes libxft-dev
RUN apt-get install --yes libpng-dev

# Switch back to the jovyan user to do pip installs or this will fail
# due to directory ownership on the cache
USER $NB_USER

# Maybe not strictly necessary, but often a good idea to have around
RUN pip install virtualenv
RUN pip2 install virtualenv

# Basic analysis packages
RUN pip install --upgrade numpy
RUN pip2 install --upgrade numpy
RUN pip install --upgrade pandas
RUN pip2 install --upgrade pandas

# Install Plot.ly for most visualization needs
RUN pip install plotly
RUN pip2 install plotly

# Matplotlib in case anyone actually wants that. ;-)
RUN pip install --upgrade matplotlib
RUN pip2 install --upgrade matplotlib

# Machine learning modules
RUN pip install --upgrade scikit-learn
RUN pip2 install --upgrade scikit-learn
RUN pip install --upgrade sklearn
RUN pip2 install --upgrade sklearn
RUN pip install --upgrade sklearn-extensions 
RUN pip2 install --upgrade sklearn-extensions 

# Elasticsearch client for Python.  The DSL (high level) version also installs
# the standard elasticsearch-py library as a dependency, so it's available
# even though we don't explicity install it here.
RUN pip install --upgrade elasticsearch-dsl
RUN pip2 install --upgrade elasticsearch-dsl

# The first time you 'import plotly' on a new system, it has to build the
# font cache.  This takes a while and also causes spurious warnings, so
# we can just do that during the build process and the user never has to
# see it.
RUN /bin/bash -c 'source /opt/conda/bin/activate && echo 'import plotly' | python -'
RUN /bin/bash -c 'source /opt/conda/envs/python2/bin/activate && echo 'import plotly' | python -'
RUN conda env list