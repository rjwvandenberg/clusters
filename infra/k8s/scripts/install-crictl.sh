#!/bin/bash
VERSION="v1.29.0" # check latest version in /releases page
curl -L --fail --remote-name-all https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar -C /usr/local/bin --no-same-owner -zxvf crictl-$VERSION-linux-amd64.tar.gz
rm -f crictl-$VERSION-linux-amd64.tar.gz