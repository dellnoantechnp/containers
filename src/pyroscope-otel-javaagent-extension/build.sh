#!/bin/bash
set -euo pipefail

GITHUB_PROJECT_API_URL="https://api.github.com/repos/grafana/otel-profiling-java/releases"
REGISTRY=docker.io
REPOSITORY=dellnoantechnp/pyroscope-otel-javaagent-extension
TAG="2.1.1"

IMAGE="${REGISTRY}/${REPOSITORY}:v${TAG}"
IMAGE_LATEST="${REGISTRY}/${REPOSITORY}:latest"

CONTAINER_TOOL=docker

BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") # 符合 RFC 3339 格式
BUILD_AUTHOR=dellnoantechnp
BUILD_IMAGE_URL="https://github.com/grafana/otel-profiling-java"

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
  # success return code
  return 0
}

# ── 从 GitHub API 获取 releases 列表 ──────────────────────
fetch_releases() {
  local url="${GITHUB_PROJECT_API_URL}?per_page=10"
  echo -n "Fetching releases from GitHub ... "
  local http_code
  http_code=$(curl -s -o /tmp/pyroscope-releases.json -w "%{http_code}" "$url")
  if [[ $http_code -ne 200 ]]; then
    echo "failed (HTTP $http_code). Use default version." >&2
    return 1
  fi
  echo "done."
  return 0
}

# ── 交互式选择版本号（whiptail） ──────────────────────────
select_version() {
  local items
  items=$(jq -r '.[] | "\(.tag_name) \(.name // .title // "")"' /tmp/pyroscope-releases.json 2>/dev/null)

  if [[ -z "$items" ]]; then
    echo "No releases found. Use default version." >&2
    return 1
  fi

  # 用索引数组保存 tag，opts 使用数字索引作为 value
  local -a tags=()
  local -a opts=()
  local idx=0
  while IFS= read -r line; do
    local val desc
    val="${line%% *}"
    desc="${line#* }"
    tags+=("$val")
    opts+=( "$((idx + 1))" "$desc" )
    (( idx++ )) || true
  done <<< "$items"

  # whiptail 返回用户选择的索引号（如 "3"）
  local selected
  selected=$(whiptail --title "Select Pyroscope Java Version" \
    --menu "Choose a release tag (arrow keys + Enter):" \
    16 70 10 "${opts[@]}" 3>&1 1>&2 2>&3 3>&-) || {
    echo "Cancelled by user. Use default version." >&2
    return 1
  }

  if [[ -z "$selected" ]]; then
    echo "Cancelled by user. Use default version." >&2
    return 1
  fi

  # 通过索引取回 tag，去掉 v 前缀
  TAG="${tags[idx=$((selected - 1))]}"
  echo "Selected version: $TAG"
  return 0
}

# ── 主流程 ────────────────────────────────────────────────
# 优先使用环境变量，否则尝试交互式选择，最后回退到默认值
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
