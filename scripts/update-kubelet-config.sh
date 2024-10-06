#!/usr/bin/env bash

set -euo pipefail

if=$1

node_ip=$(ip -4 addr show ${if} | grep "inet" | head -1 | awk '{print $2}' | cut -d/ -f1)

echo "KUBELET_EXTRA_ARGS=--node-ip=${node_ip}" | \
  tee /etc/default/kubelet

systemctl daemon-reload
systemctl restart kubelet
