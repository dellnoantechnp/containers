#!/bin/bash

REGISTRY=docker.io
REPOSITORY=dellnoantechnp/pyroscope-instrumentation-java
TAG=${VERSION:-2.9.0}

IMAGE="${REGISTRY}/${REPOSITORY}:v${TAG}"
IMAGE_LATEST="${REGISTRY}/${REPOSITORY}:latest"

CONTAINER_TOOL=docker

BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") # 符合 RFC 3339 格式
BUILD_AUTHOR=dellnoantechnp
BUILD_IMAGE_URL="https://github.com/grafana/pyroscope-java"

# 编译镜像
function build_push() {
  local image
  image=$1

  echo "INFO: build push images [${image}]..."
  ${CONTAINER_TOOL} buildx build \
          --output type=image,push=true,oci-mediatypes=true \
          --metadata-file ./build-metadata.json \
          --build-arg=version="${TAG}" \
          --build-arg=BUILD_DATE="${BUILD_DATE}" \
          --build-arg=BUILD_AUTHOR=${BUILD_AUTHOR} \
          --build-arg=BUILD_IMAGE_URL=${BUILD_IMAGE_URL} \
          -t "${image}" \
          -t "${IMAGE_LATEST}" .
}

# 推送镜像至镜像仓库并清理本地镜像
function push_doc() {
  local image name
  image=$1

  # pushrm plugin upload README.md description
  if [[ -f README.md ]]; then
    name="${image%:*}"
    echo -e "INFO: Using `pushrm` plugin upload [${name}] description from \e[33mREADME.md\e[0m"
    if [[ -f description.txt ]]; then
      ${CONTAINER_TOOL} pushrm -s "$(cat description.txt)" "${name}"
    else
      ${CONTAINER_TOOL} pushrm "${name}"
    fi
  fi
}

build_push "${IMAGE}"
push_doc "${IMAGE}"
