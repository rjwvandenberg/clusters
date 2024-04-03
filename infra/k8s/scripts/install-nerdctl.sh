#!/bin/sh
VERSION="1.7.5"
curl -L --fail --remote-name-all https://github.com/containerd/nerdctl/releases/download/v$VERSION/nerdctl-$VERSION-linux-amd64.tar.gz
sudo tar -C /usr/local/bin --no-same-owner -xzvf nerdctl-$VERSION-linux-amd64.tar.gz nerdctl
rm nerdctl-$VERSION-linux-amd64.tar.gz
