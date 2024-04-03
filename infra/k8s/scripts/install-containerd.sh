#!/bin/sh
curl -L --fail --remote-name-all https://github.com/containerd/containerd/releases/download/v2.0.0-rc.0/containerd-2.0.0-rc.0-linux-amd64.tar.gz
sudo tar -C /usr/local --no-same-owner -xzvf containerd-2.0.0-rc.0-linux-amd64.tar.gz
rm containerd-2.0.0-rc.0-linux-amd64.tar.gz
curl -L --fail --remote-name-all https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mkdir -p /usr/local/lib/systemd/system
sudo cp containerd.service /usr/local/lib/systemd/system
rm containerd.service
sudo systemctl enable containerd