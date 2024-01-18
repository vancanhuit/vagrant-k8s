# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-12"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.define "control-plane" do |node|
    node.vm.hostname = "control-plane"
    node.vm.network "private_network", ip: "192.168.56.10"
  end

  (1..2).each do |i|
    hostname = "node-#{'%02d' % i}"
    config.vm.define "#{hostname}" do |node|
      node.vm.hostname = "#{hostname}"
      node.vm.network "private_network", ip: "192.168.56.#{10 + i}"
    end
  end

  config.vm.provision "shell", name: "disable-swap", path: "disable-swap.sh", privileged: false
  config.vm.provision "shell", name: "install-essential-tools", path: "install-essential-tools.sh", privileged: false
  config.vm.provision "shell", name: "allow-bridge-nf-traffic", path: "allow-bridge-nf-traffic.sh", privileged: false
  config.vm.provision "shell", name: "install-containerd", path: "install-containerd.sh", privileged: false
  config.vm.provision "shell", name: "install-kubeadm", path: "install-kubeadm.sh", privileged: false
  config.vm.provision "shell", name: "update-kubelet-config", path: "update-kubelet-config.sh", args: ["eth1"], privileged: false
end
