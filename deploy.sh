#!/bin/#!/usr/bin/env bash

# Simple script called by Travis CI to push the Docker images we just built to
# Docker hub.

echo "REPO is $REPO"
echo "IMAGE_NAME is $IMAGE_NAME"
echo "DATE is $DATE"
echo "TRAVIS_BUILD_NUMBER is $TRAVIS_BUILD_NUMBER"
echo "DOCKERHUB_USER is $DOCKERHUB_USER"

docker login -u "$DOCKERHUB_USER" -p "$DOCKERHUB_PASS"
