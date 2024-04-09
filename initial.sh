#!/bin/bash

docker buildx create --name dellnoantechnp_builder --driver docker-container
docker buildx use dellnoantechnp_builder
