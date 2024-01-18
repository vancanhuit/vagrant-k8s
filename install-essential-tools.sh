#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

echo "grub-pc grub-pc/install_devices multiselect /dev/sda1" | sudo debconf-set-selections

sudo apt-get update
sudo apt-get --quiet --yes \
            --option "Dpkg::Options::=--force-confdef" \
            --option "Dpkg::Options::=--force-confold" \
            dist-upgrade
sudo apt-get --quiet --yes install git \
                            vim curl \
                            wget htop tmux jq net-tools resolvconf

cp -v /vagrant/.vimrc ~/.vimrc
cp -v /vagrant/.tmux.conf ~/.tmux.conf

sudo timedatectl set-timezone 'Asia/Ho_Chi_Minh'
sudo dpkg-reconfigure --frontend=${DEBIAN_FRONTEND} tzdata

echo "nameserver 1.1.1.1" | sudo tee /etc/resolvconf/resolv.conf.d/head
echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolvconf/resolv.conf.d/head
sudo resolvconf -u
