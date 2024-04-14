#!/bin/sh
set -e
curl -L --fail --remote-name-all $URL
echo $CHECKSUM runc.$ARCH | sha256sum --check
sudo install -m 755 runc.$ARCH /usr/local/sbin/runc
rm runc.$ARCH