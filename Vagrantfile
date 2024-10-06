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
    node.vm.provision "shell", name: "configure-firewall", path: "scripts/configure-control-plane-firewall.sh", privileged: true
  end

  (1..2).each do |i|
    hostname = "node-#{'%02d' % i}"
    config.vm.define "#{hostname}" do |node|
      node.vm.hostname = "#{hostname}"
      node.vm.network "private_network", ip: "192.168.56.#{10 + i}"
      node.vm.provider "virtualbox" do |vb|
        vb.cpus = 1
      end
      node.vm.provision "shell", name: "configure-firewall", path: "scripts/configure-worker-node-firewall.sh", privileged: true
    end
  end

  config.vm.provision "shell", name: "disable-swap", path: "scripts/disable-swap.sh", privileged: true
  config.vm.provision "shell", name: "install-essential-tools", path: "scripts/install-essential-tools.sh", privileged: true
  config.vm.provision "shell", name: "allow-bridge-nf-traffic", path: "scripts/allow-bridge-nf-traffic.sh", privileged: true
  config.vm.provision "shell", name: "install-containerd", path: "scripts/install-containerd.sh", privileged: true
  config.vm.provision "shell", name: "install-kubeadm", path: "scripts/install-kubeadm.sh", privileged: true
  config.vm.provision "shell", name: "update-kubelet-config", path: "scripts/update-kubelet-config.sh", args: ["eth1"], privileged: true
  config.vm.provision "shell", name: "misc", path: "scripts/misc.sh", privileged: false
end
