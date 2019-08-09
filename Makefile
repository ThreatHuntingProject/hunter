REPO=threathuntproj
IMAGE_NAME=hunting

# Point this to the full path of a directory you want to mount as your "work"
# volume inside the container.  This will become "/home/jovyan/work" (Jupyter
# default value)
DATAVOL=$(HOME)

# change this to the local port on which you'd like to connect to the
# container.  Usually you can just leave this as-is.
LOCALPORT=8888

build:	Dockerfile refresh
	docker build --build-arg JUPYTER_NB_PASS=$$JUPYTER_NB_PASS -t $(REPO)/$(IMAGE_NAME):dev .

refresh:
	docker pull jupyter/pyspark-notebook

test:
	@echo "\n************************"
	@echo "Testing basic functionality with Python 3..."
	docker run -v `pwd`:/home/jovyan/work $(REPO)/$(IMAGE_NAME):dev jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=60 --output /tmp/testoutput-py3.ipynb /home/jovyan/work/Test.ipynb
	@echo "Testing Apache Spark support with Python 3..."
	docker run -v `pwd`:/home/jovyan/work $(REPO)/$(IMAGE_NAME):dev jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=60 --output /tmp/testoutput-spark-py3.ipynb /home/jovyan/work/Test-spark.ipynb

run:
	docker run -it -p $(LOCALPORT):8888 --user root -e GRANT_SUDO=yes -e GEN_CERT=yes -v $(DATAVOL):/home/jovyan/work $(REPO)/$(IMAGE_NAME):dev

run-lab:
	docker run -it -p $(LOCALPORT):8888 --user root -e GRANT_SUDO=yes -e GEN_CERT=yes -e JUPYTER_ENABLE_LAB=yes -v $(DATAVOL):/home/jovyan/work $(REPO)/$(IMAGE_NAME):dev

