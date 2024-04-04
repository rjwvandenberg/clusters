#!/bin/bash
VERSION="v0.13.1"
curl -L --fail --remote-name-all https://github.com/moby/buildkit/releases/download/$VERSION/buildkit-$VERSION.linux-amd64.tar.gz
sudo tar -C /usr/local --no-same-owner -xzvf buildkit-$VERSION.linux-amd64.tar.gz
rm buildkit-$VERSION.linux-amd64.tar.gz
curl -L --fail --remote-name-all https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/system/buildkit.socket
sudo cp buildkit.socket /usr/local/lib/systemd/system
rm buildkit.socket
curl -L --fail --remote-name-all https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/system/buildkit.service
sudo cp buildkit.service /usr/local/lib/systemd/system
rm buildkit.service
sudo systemctl enable buildkit.socket
