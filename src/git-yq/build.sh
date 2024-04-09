#!/bin/bash

COMMON_PARAMETERS="--platform linux/amd64,linux/arm64 --push --progress plain"

docker buildx build -t dellnoantechnp/git-yq:2.44 ${COMMON_PARAMETERS} .

docker buildx build -t dellnoantechnp/git-yq:git_2.44_yq_4.43_jq_1.6 ${COMMON_PARAMETERS} .

docker buildx build -t dellnoantechnp/git-yq:latest ${COMMON_PARAMETERS} .
