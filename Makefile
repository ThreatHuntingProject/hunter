DATE=`date '+%Y%m%d'`
REPO="threathuntproj"
IMAGE_NAME="hunting"

# Point this to the full path of a directory you want to mount as your "work"
# volume inside the container.  This will become "/home/jovyan/work" (Jupyter
# default value)
DATAVOL=$(HOME)

# change this to the local port on which you'd like to connect to the
# container.  Usually you can just leave this as-is.
LOCALPORT=8888

build:	Dockerfile refresh
	docker build --build-arg JUPYTER_NB_PASS=$$JUPYTER_NB_PASS -t $(REPO)/$(IMAGE_NAME):latest -t $(REPO)/$(IMAGE_NAME):$(DATE) .

refresh:
	docker pull jupyter/pyspark-notebook

run:
	docker run -it -p $(LOCALPORT):8888 -e GEN_CERT=yes -v $(DATAVOL):/home/jovyan/work $(REPO)/$(IMAGE_NAME)

push:
	docker push $(REPO)/$(IMAGE_NAME):latest
	docker push $(REPO)/$(IMAGE_NAME):$(DATE)
