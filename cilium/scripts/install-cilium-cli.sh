#!/bin/sh
CILIUM_CLI_VERSION=v0.16.4
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar -C /usr/local/bin --no-same-owner -xzvf cilium-linux-${CLI_ARCH}.tar.gz
rm cilium-linux-${CLI_ARCH}.tar.gz
rm cilium-linux-${CLI_ARCH}.tar.gz.sha256sum