#!/bin/bash

cd "$HOME" || exit 
CONTAINERD_VERSION="1.6.13"
curl -LfsS https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -o containerd.tar.gz
sudo tar Cxzvf /usr/local containerd.tar.gz
sudo mkdir -pv /usr/local/lib/systemd/system
sudo cp -v /vagrant/containerd.service /usr/local/lib/systemd/system/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

rm -fv containerd.tar.gz

RUNC_VERSION="1.1.4"
curl -LfsSO https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64
sudo install -o root -g root -m 755 runc.amd64 /usr/local/sbin/runc

rm -fv runc.amd64

CNI_PLUGINS_VERSION="1.1.1"
curl -LfsS https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz -o cni-plugins.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins.tgz

rm -fv cni-plugins.tgz

sudo mkdir -p /etc/containerd
sudo cp -v /vagrant/containerd-config.toml /etc/containerd/config.toml

sudo systemctl restart containerd
