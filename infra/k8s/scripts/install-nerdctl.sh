#!/bin/sh
VERSION="1.7.5"
curl -L --fail --remote-name-all https://github.com/containerd/nerdctl/releases/download/v$VERSION/nerdctl-$VERSION-linux-$ARCH.tar.gz
sudo tar -C /usr/local/bin --no-same-owner -xzvf nerdctl-$VERSION-linux-$ARCH.tar.gz nerdctl
rm nerdctl-$VERSION-linux-$ARCH.tar.gz
