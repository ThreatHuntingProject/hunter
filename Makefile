REPO=threathuntproj
IMAGE_NAME=hunting
BUILD_TAG="slim-dev"

# Point this to the full path of a directory you want to mount as your "work"
# volume inside the container.  This will become "/home/jovyan/work" (Jupyter
# default value)
DATAVOL=$(HOME)

# change this to the local port on which you'd like to connect to the
# container.  Usually you can just leave this as-is.
LOCALPORT=8888

build:	Dockerfile refresh base hunter
	docker build --target sparkhunter  -t $(REPO)/$(IMAGE_NAME):$(BUILD_TAG)-spark .

base: Dockerfile refresh
	docker build --target hunterbase -t $(REPO)/$(IMAGE_NAME):$(BUILD_TAG)-base .

hunter: Dockerfile base
	docker build --target hunter --build-arg JUPYTER_NB_PASS=$$JUPYTER_NB_PASS -t $(REPO)/$(IMAGE_NAME):$(BUILD_TAG) .

refresh:
	docker pull debian:stable-slim
	git submodule update

test:
	@echo "\n************************"
	@echo "Testing with Python 3 Kernel..."
	docker run -v `pwd`:/home/jovyan/work $(REPO)/$(IMAGE_NAME):$(BUILD_TAG) jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=60 --output /tmp/testoutput-py3.ipynb /home/jovyan/work/Test.ipynb
	@echo "\n************************"
	@echo "Testing Spark Notebook..."
	docker run -v `pwd`:/home/jovyan/work $(REPO)/$(IMAGE_NAME):$(BUILD_TAG)-spark jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=60 --output /tmp/testoutput-py3.ipynb /home/jovyan/work/TestSpark.ipynb 



run:
	docker run -it -p $(LOCALPORT):8888 --user root -e GRANT_SUDO=yes -e GEN_CERT=yes -v $(DATAVOL):/home/jovyan/work $(REPO)/$(IMAGE_NAME):$(BUILD_TAG)

run-lab:
	docker run -it -p $(LOCALPORT):8888 --user root -e GRANT_SUDO=yes -e GEN_CERT=yes -e JUPYTER_ENABLE_LAB=yes -v $(DATAVOL):/home/jovyan/work $(REPO)/$(IMAGE_NAME):$(BUILD_TAG)
