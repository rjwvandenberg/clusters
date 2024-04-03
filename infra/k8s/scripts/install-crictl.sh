#!/bin/bash
VERSION="v1.29.0" # check latest version in /releases page
curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz --output crictl-$VERSION-linux-amd64.tar.gz
sudo tar -zxvf --no-same-owner crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz