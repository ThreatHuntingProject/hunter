#!/bin/bash

# Simple script called by Travis CI to push the Docker images we just built to
# Docker hub.

echo "Logging into Docker Hub"
echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
echo "Pushing $REPO/$IMAGE_NAME:latest"
docker push $REPO/$IMAGE_NAME:latest
echo "Pushing $REPO/$IMAGE_NAME:$DATE.$TRAVIS_BUILD_NUMBER"
docker push $REPO/$IMAGE_NAME:$DATE.$TRAVIS_BUILD_NUMBER
echo "Pushing $REPO/$IMAGE_NAME:$DATE"
docker push $REPO/$IMAGE_NAME:$DATE
