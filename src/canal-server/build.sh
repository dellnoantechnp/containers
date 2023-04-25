#!/bin/bash
url=https://github.com/alibaba/canal/releases/download/canal-1.1.7-alpha-1/canal.deployer-1.1.7-SNAPSHOT.tar.gz

echo "1. Download release ..."
curl -C - -Lo canal.deployer.tar.gz https://github.com/alibaba/canal/releases/download/canal-1.1.7-alpha-1/canal.deployer-1.1.7-SNAPSHOT.tar.gz

echo "2. Build container ..."
VERSION=$(echo $url | grep -Po "(?<=canal.deployer-)(\d.){2}\d(-[[:upper:]]+){0,1}(?=.tar.gz)")
docker build -t canal-server:${VERSION} -f Dockerfile .