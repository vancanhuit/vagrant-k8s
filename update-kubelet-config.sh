#!/bin/bash

set -e

if=$1

node_ip=$(ip -4 addr show ${if} | grep "inet" | head -1 | awk '{print $2}' | cut -d/ -f1)

echo "KUBELET_EXTRA_ARGS=--node-ip=${node_ip}" | sudo tee /etc/default/kubelet

sudo systemctl daemon-reload
sudo systemctl restart kubelet