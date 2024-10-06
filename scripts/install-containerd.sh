#!/usr/bin/env bash

set -euo pipefail

cleanup() {
  echo "Cleaning up ..."
  rm -fv containerd.tar.gz || true
  rm -fv runc.amd64 || true
  rm -fv cni-plugins.tgz || true
}

trap cleanup EXIT SIGINT SIGTERM

CONTAINERD_VERSION="1.6.36"
curl -LfsS https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -o containerd.tar.gz
tar Cxzvf /usr/local containerd.tar.gz

CONTAINERD_CONFIG_FILE=/etc/containerd/config.toml
mkdir -pv $(dirname ${CONTAINERD_CONFIG_FILE})
containerd config default | tee ${CONTAINERD_CONFIG_FILE} > /dev/null
sed -i 's/^\(\s*SystemdCgroup\)\s*=\s*false$/\1 = true/' ${CONTAINERD_CONFIG_FILE}
grep 'SystemdCgroup' ${CONTAINERD_CONFIG_FILE}
sed -i 's|^\(\s*sandbox_image\)\s*=\s*\(.*\)$|\1 = "registry.k8s.io/pause:3.9"|' ${CONTAINERD_CONFIG_FILE}
grep 'sandbox_image' ${CONTAINERD_CONFIG_FILE}

mkdir -pv /usr/local/lib/systemd/system
cp -v /vagrant/conf/containerd.service /usr/local/lib/systemd/system/containerd.service
systemctl daemon-reload
systemctl enable --now containerd

RUNC_VERSION="1.1.14"
curl -LfsSO https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64
install -o root -g root -m 755 runc.amd64 /usr/local/sbin/runc

CNI_PLUGINS_VERSION="1.5.1"
curl -LfsS https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz -o cni-plugins.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins.tgz

systemctl restart containerd
