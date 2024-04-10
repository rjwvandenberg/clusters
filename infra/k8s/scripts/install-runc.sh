#!/bin/sh
curl -L --fail --remote-name-all https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.$ARCH
sudo install -m 755 runc.$ARCH /usr/local/sbin/runc
rm runc.$ARCH