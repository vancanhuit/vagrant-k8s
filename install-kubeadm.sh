#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install --quiet --yes apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install --quiet --yes kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
