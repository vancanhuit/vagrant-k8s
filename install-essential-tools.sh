#!/bin/bash

sudo apt-get update
sudo apt-get --yes upgrade
sudo apt-get --yes install git vim curl wget htop tmux

cp -v /vagrant/.vimrc ~/.vimrc
cp -v /vagrant/.tmux.conf ~/.tmux.conf
