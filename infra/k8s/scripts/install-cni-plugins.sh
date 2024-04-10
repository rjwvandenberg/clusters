#!/bin/bash
curl -L --fail --remote-name-all https://github.com/containernetworking/plugins/releases/download/v1.4.1/cni-plugins-linux-$ARCH-v1.4.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar --no-same-owner -zxvf cni-plugins-linux-$ARCH-v1.4.1.tgz -C /opt/cni/bin
rm cni-plugins-linux-$ARCH-v1.4.1.tgz