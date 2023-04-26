#!/bin/bash

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
  read -t 5 -p "Please choose number: " choose_item
  url=$(echo "${RELEASE_LIST}" | head -"${choose_item}" | tail -1 | grep -Po 'https://.*tar.gz')
}

choose_releases

url=${url:=https://github.com/alibaba/canal/releases/download/canal-1.1.7-alpha-1/canal.deployer-1.1.7-SNAPSHOT.tar.gz}
echo "INFO: download url --> ${url}"


echo "1. Download release ..."
rm -rf ${url##*/}
curl -C - -LO ${url}
ln -sfT ${url##*/} canal.deployer.tar.gz

echo "2. Build container ..."
VERSION=$(echo ${url} | grep -Po "(?<=canal.deployer-)(\d.){2}\d(-[[:upper:]]+){0,1}(?=.tar.gz)")
docker build -t canal-server:${VERSION} -f Dockerfile .