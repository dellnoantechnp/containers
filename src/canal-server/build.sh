#!/bin/bash
#
# Maintainer: dellnoantechnp  dellnoantechnp@gmail.com
# Project: https://github.com/dellnoantechnp/containers
# Note: Manual build use this script.
#

DEFAULT_CANAL_VERSION_PATH=https://github.com/alibaba/canal/releases/download/canal-1.1.6-hotfix-1/canal.deployer-1.1.6.tar.gz

function usage() {
  echo "help message."
  echo -e "\nUsage: bash build.sh [build|download|help]\n"
}

function choose_releases(){
  local COUNT=1
  RELEASE_LIST=$(curl -s -L -H "Accept: application/vnd.github+json"  \
      -H "X-GitHub-Api-Version: 2022-11-28"  \
      'https://api.github.com/repos/alibaba/canal/releases?per_page=10' \
      | grep -Po '((?<=tag_name": ").*(?=")|(?<=browser_download_url": ")http.*canal.deployer-.*(?<="))' \
      | paste - -)
  while read -r line; do
    printf "[%-2s]  -->   %s\n" ${COUNT} "${line}"
    let COUNT=$COUNT+1
  done < <(echo "${RELEASE_LIST}")
  read -t 5 -p $'Please choose number[5s]\e[5m:\e[0m ' choose_item
  echo
  url=$(echo "${RELEASE_LIST}" | head -"${choose_item}" | tail -1 | grep -Po 'https://.*tar.gz')
}

function download_release(){
  ## Default release version.
  url=${url:=${DEFAULT_CANAL_VERSION_PATH}}
  echo "INFO: download url --> ${url}"

  [[ -f ${url##*/} ]] && rm -rf ${url##*/}
  curl -C - -LO ${url}
  ln -sfT ${url##*/} canal.deployer.tar.gz
}

function build_container(){
  ## only support localhost.
  VERSION=$(echo ${url} | grep -Po "(?<=canal.deployer-)(\d.){2}\d(-[[:upper:]]+){0,1}(?=.tar.gz)")
  docker build -t canal-server:${VERSION} -f Dockerfile .
}

case $1 in
build)
  choose_releases
  echo "1. Download release ..."
  download_release
  echo "2. Build container ..."
  build_container
  ;;
download)
  choose_releases
  echo "1. Download release ..."
  download_release
  ;;
*)
  usage
  ;;
esac