#!/bin/sh
VERSION=v3.14.3
curl -L --fail --remote-name-all https://get.helm.sh/helm-$VERSION-linux-$ARCH.tar.gz
sudo tar -C /usr/local/bin --no-same-owner --strip-components 1 -xzvf helm-$VERSION-linux-$ARCH.tar.gz linux-$ARCH/helm
rm helm-$VERSION-linux-$ARCH.tar.gz