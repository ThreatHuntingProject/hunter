# hunter
A standalone hunting analysis toolset in a Docker container.  Provides Jupyter notebook, visualization modules and Spark support.

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

This will start a new container, which you can stop/start as you like.  _Each time you use 'make run', you'll create a new persistent container_.  Be careful not to run 'make run' more than once unless you know what you're doing.

# Accessing the Notebook Server
By default, when the notebook server runs, it will print the UI URL to the console.  This URL contains a randomly-generated access token, which will serve instead of a password to authenticate you to the notebook server.  Click that URL, or cut-n-paste it into your browser, and you'll be logged in.

If you've set a password at build time (via the JUPYTER_NB_PASS variable), then there will be no default URL.  Instead, just browse to _https://localhost:8888_.

**NOTE: This image uses SSL, so all access URLs must start with _https://_.**
