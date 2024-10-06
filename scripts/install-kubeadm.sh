#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

K8S_VERSION=1.30

apt-get update
apt-get install --quiet --yes apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | \
  tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install --quiet --yes kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
