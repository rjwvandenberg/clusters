#!/bin/sh
# exit on error
set -e
curl -L --fail --remote-name-all --output download.tar.gz $URL
echo $CHECKSUM download.tar.gz | sha256sum --check
tar -C $UNTAR_PATH --no-same-owner -xzvf download.tar.gz $FILTER
rm download.tar.gz