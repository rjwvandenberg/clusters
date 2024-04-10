#!/bin/sh
HUBBLE_VERSION="v0.13.2"
if [ "$(uname -m)" = "aarch64" ]; then ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${ARCH}.tar.gz.sha256sum
sudo tar -C /usr/local/bin --no-same-owner -xzvf hubble-linux-${ARCH}.tar.gz
rm hubble-linux-${ARCH}.tar.gz
rm hubble-linux-${ARCH}.tar.gz.sha256sum