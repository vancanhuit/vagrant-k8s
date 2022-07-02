#!/bin/bash

cd $HOME
wget https://github.com/containerd/containerd/releases/download/v1.6.6/containerd-1.6.6-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.6.6-linux-amd64.tar.gz
sudo mkdir -p /usr/local/lib/systemd/system
sudo cp -v /vagrant/containerd.service /usr/local/lib/systemd/system/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

rm -fv containerd-1.6.6-linux-amd64.tar.gz

wget https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

rm -fv runc.amd64

wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz

rm -fv cni-plugins-linux-amd64-v1.1.1.tgz

sudo mkdir -p /etc/containerd
sudo cp -v /vagrant/containerd-config.toml /etc/containerd/config.toml

sudo systemctl restart containerd
