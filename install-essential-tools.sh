#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get --quiet --yes dist-upgrade
sudo apt-get --quiet --yes install git vim curl wget htop tmux jq

wget https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_linux_amd64
sudo install -m 0755 yq_linux_amd64 /usr/local/bin/yq

rm -v yq_linux_amd64

cp -v /vagrant/.vimrc ~/.vimrc
cp -v /vagrant/.tmux.conf ~/.tmux.conf
