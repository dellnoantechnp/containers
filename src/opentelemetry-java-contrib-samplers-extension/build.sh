#!/bin/bash
set -euo pipefail

# OpenTelemetry Java Contrib project maven artifact base url
OTEL_JAVA_CONTRIB_BASE="https://repo1.maven.org/maven2/io/opentelemetry/contrib/"
# OpenTelemetry Java Contrib project name on maven path
OTEL_JAVA_CONTRIB_EXTENSION="opentelemetry-samplers/"

DEFAULT_TAG="1.43.0-alpha"
REGISTRY=docker.io
REPOSITORY=dellnoantechnp/opentelemetry-java-contrib-samplers-extension
TAG="$DEFAULT_TAG"

# ── 工具检查 ──────────────────────────────────────────────
check_tools() {
  local missing=0
  for tool in curl jq whiptail; do
    if ! command -v "$tool" &>/dev/null; then
      echo "ERROR: '$tool' is required but not found. Install it and retry." >&2
      missing=1
    fi
  done
  [[ $missing -eq 1 ]] && exit 1
  return 0
}

# ── 从 Maven Central 获取可用版本列表 ──────────────────────
fetch_releases() {
  local url="${OTEL_JAVA_CONTRIB_BASE%/}/${OTEL_JAVA_CONTRIB_EXTENSION%/}/maven-metadata.xml"
  echo -n "Fetching versions from Maven Central ... "
  local http_code
  http_code=$(curl -s -o /tmp/otel-samplers-metadata.xml -w "%{http_code}" "$url")
  if [[ $http_code -ne 200 ]]; then
    echo "failed (HTTP $http_code). Use default version." >&2
    return 1
  fi

  local versions
  versions=$(sed -n '/<versions>/,/<\/versions>/p' /tmp/otel-samplers-metadata.xml \
    | sed -n 's/.*<version>\([^<]*\)<\/version>.*/\1/p' 2>/dev/null)
  if [[ -z "$versions" ]]; then
    echo "no versions found. Use default version." >&2
    return 1
  fi

  echo "done."
  return 0
}

# ── 交互式选择版本号（whiptail） ──────────────────────────
select_version() {
  local items
  items=$(sed -n '/<versions>/,/<\/versions>/p' /tmp/otel-samplers-metadata.xml \
    | sed -n 's/.*<version>\([^<]*\)<\/version>.*/\1/p' 2>/dev/null | sort -V | tac)

  if [[ -z "$items" ]]; then
    echo "No versions found. Use default version." >&2
    return 1
  fi

  local -a tags=()
  local -a opts=()
  local idx=0
  while IFS= read -r ver; do
    tags+=("$ver")
    opts+=( "$((idx + 1))" "$ver" )
    (( idx++ )) || true
  done <<< "$items"

  local selected
  selected=$(whiptail --title "Select OpenTelemetry Samplers Version" \
    --menu "Choose a version (arrow keys + Enter):" \
    16 70 10 "${opts[@]}" 3>&1 1>&2 2>&3 3>&-) || {
    echo "Cancelled by user. Use default version." >&2
    return 1
  }

  if [[ -z "$selected" ]]; then
    echo "Cancelled by user. Use default version." >&2
    return 1
  fi

  TAG="${tags[idx=$((selected - 1))]}"
  echo "Selected version: $TAG"
  return 0
}

# ── 主流程 ────────────────────────────────────────────────
if [[ -n "${VERSION:-}" ]]; then
  TAG="$VERSION"
elif fetch_releases; then
  if check_tools; then
    select_version || TAG="$DEFAULT_TAG"
  else
    TAG="$DEFAULT_TAG"
  fi
else
  TAG="$DEFAULT_TAG"
fi

IMAGE="${REGISTRY}/${REPOSITORY}:${TAG}"
IMAGE_LATEST="${REGISTRY}/${REPOSITORY}:latest"

CONTAINER_TOOL=docker

BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_AUTHOR=dellnoantechnp
BUILD_IMAGE_URL="https://github.com/open-telemetry/opentelemetry-java-contrib/tree/main/opentelemetry-samplers"

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

  if [[ -f README.md ]]; then
    name="${image%:*}"
    echo -e "INFO: Using 'pushrm' plugin upload [${name}] description from \e[33mREADME.md\e[0m"
    if [[ -f description.txt ]]; then
      ${CONTAINER_TOOL} pushrm -s "$(cat description.txt)" "${name}"
    else
      ${CONTAINER_TOOL} pushrm "${name}"
    fi
  fi
}

build_push "${IMAGE}"
push_doc "${IMAGE}"
