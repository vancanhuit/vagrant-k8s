#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get --quiet --yes dist-upgrade
sudo apt-get --quiet --yes install git vim curl wget htop tmux jq net-tools

cp -v /vagrant/.vimrc ~/.vimrc
cp -v /vagrant/.tmux.conf ~/.tmux.conf
