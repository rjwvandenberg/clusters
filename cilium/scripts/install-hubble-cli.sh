#!/bin/sh
HUBBLE_VERSION="v0.13.2"
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar -C /usr/local/bin --no-same-owner -xzvf hubble-linux-${HUBBLE_ARCH}.tar.gz
rm hubble-linux-${HUBBLE_ARCH}.tar.gz
rm hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum