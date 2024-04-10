#!/bin/sh
CILIUM_CLI_VERSION=v0.16.4
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${ARCH}.tar.gz.sha256sum
sudo tar -C /usr/local/bin --no-same-owner -xzvf cilium-linux-${ARCH}.tar.gz
rm cilium-linux-${ARCH}.tar.gz
rm cilium-linux-${ARCH}.tar.gz.sha256sum