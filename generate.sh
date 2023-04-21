#!/bin/bash

IMAGE_TAG="${1}"

if [ "${IMAGE_TAG}" == "" ]; then
    echo "Provide a tag for the image (e.g. 0.13)"
    exit 1
fi

docker build -f Dockerfile -t jenkins-test:$IMAGE_TAG .
