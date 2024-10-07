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
    node.vm.provision "shell" do |s|
      s.name = "configure-firewall"
      s.path = "scripts/configure-control-plane-firewall.sh"
      s.privileged = true
    end
  end

  (1..2).each do |i|
    hostname = "node-#{'%02d' % i}"
    config.vm.define "#{hostname}" do |node|
      node.vm.hostname = "#{hostname}"
      node.vm.network "private_network", ip: "192.168.56.#{10 + i}"
      node.vm.provider "virtualbox" do |vb|
        vb.cpus = 1
      end
      node.vm.provision "shell" do |s|
        s.name = "configure-firewall"
        s.path = "scripts/configure-worker-node-firewall.sh"
        s.privileged = true
      end
    end
  end

  shell_provision_configs = [
    {
      "name" => "disable-swap",
      "path" => "scripts/disable-swap.sh"
    },
    {
      "name" => "install-essential-tools",
      "path" => "scripts/install-essential-tools.sh"
    },
    {
      "name" => "allow-bridge-nf-traffic",
      "path" => "scripts/allow-bridge-nf-traffic.sh"
    },
    {
      "name" => "install-containerd",
      "path" => "scripts/install-containerd.sh"
    },
    {
      "name" => "install-kubeadm",
      "path" => "scripts/install-kubeadm.sh"
    },
    {
      "name" => "update-kubelet-config",
      "path" => "scripts/update-kubelet-config.sh",
      "args" => ["eth1"]
    }
  ]

  shell_provision_configs.each do |cfg|
    config.vm.provision "shell" do |s|
      s.name = cfg["name"]
      s.path = cfg["path"]
      s.privileged = cfg["privileged"] ? cfg["privileged"] : true
      s.args = cfg["args"] ? cfg["args"] : []
    end
  end

  # config.vm.provision "shell", name: "disable-swap", path: "scripts/disable-swap.sh", privileged: true
  # config.vm.provision "shell", name: "install-essential-tools", path: "scripts/install-essential-tools.sh", privileged: true
  # config.vm.provision "shell", name: "allow-bridge-nf-traffic", path: "scripts/allow-bridge-nf-traffic.sh", privileged: true
  # config.vm.provision "shell", name: "install-containerd", path: "scripts/install-containerd.sh", privileged: true
  # config.vm.provision "shell", name: "install-kubeadm", path: "scripts/install-kubeadm.sh", privileged: true
  # config.vm.provision "shell", name: "update-kubelet-config", path: "scripts/update-kubelet-config.sh", args: ["eth1"], privileged: true
end
