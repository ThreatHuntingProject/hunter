# Hunter
A threat hunting / data analysis environment based on Python, Pandas, PySpark and Jupyter Notebook.

[![Build Status](https://travis-ci.com/ThreatHuntingProject/hunter.svg?branch=master)](https://travis-ci.com/ThreatHuntingProject/hunter)

The following is a partial list of the major features:

* Support for either the traditional Notebook or the new Lab interface
* Built-in extensions manager for the Notebook interface
* Python 3 (default) and Python 2 kernels
* Preinstalled libraries useful for data search, analysis and visualization, including
  * elasticsearch-dsl
  * splunk-sdk
  * pandas
  * pyspark
  * numpy
  * matplotlib
  * seaborn
  * plotly (with cufflinks support)
  * scikit-learn
  * ipywidgets

# Docker Image
This repo contains all the files and instructions necessary to build your own Docker image from scratch. If you just want to *use* the hunting environment, though, I recommend using the pre-build image available on Docker Hub.  

>  docker pull threathuntproj/hunting

This will download the image to your local cache.  Once you've downloaded the image, skip directly to the *Running the Container* section of this README and continue from there.

See [the instructions](https://hub.docker.com/r/threathuntproj/hunting/) for details.

# Prerequisites
You will need to have Docker installed and running on your system.  

To build the container, you'll also need _make_.  I typically use the version included with XCode's command line tools, but other versions may work as well, as the Makefile is not very complex.

Be sure your build system is connected to the Internet, as the process downloads and installs the latest version of many packages.  Internet access is not required to simply run the container.

I have only tested the build with Docker running on OS X, though I believe it should work pretty well with most Linux environments, too.  Of course, the host OS is irrelevant if you are just running the resulting container.

# Building
To build the container, simply do:

> make

This generally takes several minutes, and may be significantly longer if the upstream notebook image we use needs refreshing.

## Build Options
* If the JUPYTER_NB_PASS is set in your environment when you run 'make', the build script will use the variable's value as the default password for accessing the notebook server.  For example, the following will set the password to _notelling_:
> export JUPYTER_NB_PASS="notelling"

# Running the container
To run the container for the first time, simply do:

> make run

This will start a new container with the Jupyter Notebook interface, which you can stop/start as you like.  

If you prefer the Jupyter Lab interface, just do:

> make run-lab

_Each time you use `make run` or `make run-lab`, you'll create a new persistent container_.  Be careful not to run 'make run' more than once unless you know what you're doing.

If you want to have a bit more control, try something like:

> docker run -it -p 8888:8888 -e GEN_CERT=yes -v $HOME:/home/jovyan/work threathuntproj/hunting

This is essentially the same as the _make run_ method.  As written, the example will mount your home directory as the filesystem the notebooks see, but you can change this to fit your needs and preferences. To do the same with Jupyter Lab, just set the `JUPYTER_ENABLE_LAB` environment variable in the container, like so:

> docker run -it -p $(LOCALPORT):8888 -e GEN_CERT=yes -e JUPYTER_ENABLE_LAB=yes -v $(DATAVOL):/home/jovyan/work $(REPO)/$(IMAGE_NAME)

## Adding Custom Python Libraries

As a special feature, the image adds _/home/jovyan/work/lib_ to the PYTHONPATH in the container.  This is especially handy when you mount _/home/jovyan/work_ as a volume, as in the example above.  If you install a python module into that _lib_ directory, your notebooks will automatically be able to find it when they're running in the container.  This provides a convenient way for you to add your own modules without having to rebuild the entire image.

# Accessing the Jupyter Environment
By default, when the container runs, it will print the UI URL to the console.  This URL contains a randomly-generated access token, which will serve instead of a password to authenticate you to the Jupyter server.  Click that URL, or cut-n-paste it into your browser, and you'll be logged in.

If you've set a password at build time (via the JUPYTER_NB_PASS variable), then there will be no default URL.  Instead, just browse to _https://localhost:8888_.

**NOTE: This image uses SSL, so all access URLs must start with _https://_.**
