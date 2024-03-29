# We're built on the official Jupyter image for PySpark notebooks
FROM jupyter/pyspark-notebook:latest

# But if it all breaks, blame us instead
LABEL maintainer="The ThreatHunting Project <project@threathunting.net>"

# Switch back to the jovyan user to do module installs or this will fail
# due to directory ownership on the cache
USER $NB_USER

# Install Python packages.
ENV INSTALL_PACKAGES_PIP plotly elasticsearch-dsl seaborn scikit-learn ipywidgets tqdm requests dask pyspark splunk-sdk huntlib
RUN pip install jupyter_contrib_nbextensions ${INSTALL_PACKAGES_PIP}

# Set up some Jupyter Notebook extensions
RUN jupyter nbextension enable toc2/main && \
  jupyter nbextension enable execute_time/ExecuteTime && \
  jupyter nbextension enable python-markdown/main

# Set up some useful Jupyter Lab extensions
RUN jupyter labextension install --minimize=false jupyterlab-plotly  @jupyterlab/toc

# The first time you 'import plotly' on a new system, it has to build the
# font cache.  This takes a while and also causes spurious warnings, so
# we can just do that during the build process and the user never has to
# see it.
RUN /opt/conda/bin/python -c 'import plotly' 

# Set the notebook default password
ADD passwd-helper.py /tmp
ARG JUPYTER_NB_PASS
RUN mkdir -p /home/jovyan/.jupyter ; JUPYTER_NB_PASS=${JUPYTER_NB_PASS}  python /tmp/passwd-helper.py >> /home/jovyan/.jupyter/jupyter_notebook_config.py

# Add "/home/jovyan/work/lib" to the PYTHONPATH.  Since "/home/jovyan/work"
# is typically a mounted volume, this gives the user a convenient place to
# drop their own Python modules that will be available in all notebooks.
ENV PYTHONPATH "/home/jovyan/work/lib:$PYTHONPATH"
