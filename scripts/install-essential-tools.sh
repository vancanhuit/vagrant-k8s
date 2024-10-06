#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

echo "grub-pc grub-pc/install_devices multiselect /dev/sda1" | debconf-set-selections

apt-get update
apt-get --quiet --yes \
            --option "Dpkg::Options::=--force-confdef" \
            --option "Dpkg::Options::=--force-confold" \
            dist-upgrade
apt-get --quiet --yes install git \
                            curl ufw \
                            wget htop jq net-tools resolvconf socat

timedatectl set-timezone 'Asia/Ho_Chi_Minh'
timedatectl set-ntp true
dpkg-reconfigure --frontend=${DEBIAN_FRONTEND} tzdata

echo "nameserver 1.1.1.1" | tee /etc/resolvconf/resolv.conf.d/head
echo "nameserver 1.0.0.1" | tee -a /etc/resolvconf/resolv.conf.d/head
resolvconf -u

ufw allow ssh
ufw enable
