# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/bullseye64"
  config.vm.base_mac = nil

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 1
  end

  config.vm.define "master" do |node|
    node.vm.hostname = "master"
    node.vm.network "private_network", ip: "192.168.56.10"
    node.vm.provider "virtualbox" do |vb|
      vb.cpus = 2
    end
  end

  (1..2).each do |i|
    config.vm.define "worker-#{i}" do |node|
      node.vm.hostname = "worker-#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{10 + i}" 
    end
  end

  config.vm.provision "shell", path: "install-essential-tools.sh", privileged: false
  config.vm.provision "shell", path: "allow-bridge-nf-traffic.sh", privileged: false
  config.vm.provision "shell", path: "install-docker.sh", privileged: false
  config.vm.provision "shell", path: "install-kubeadm.sh", privileged: false
end
