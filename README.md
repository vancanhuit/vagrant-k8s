# Creating a multi-node Kubernetes cluster on local machine

You need to install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/) on your machine. Make sure your machine has enough RAM to run multiple VMs.

## Provisioning VMs
```sh
$ git clone https://github.com/vancanhuit/vagrant-k8s.git
$ cd vagrant-k8s
$ vagrant up
$ vagrant reload
```

## Iniitializing master node
After all VMs are provisioned, we have Docker, `kubeadm`, `kubelet` and `kubectl` installed on those VMs. We are ready to follow this [guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/) to setup our cluster:

```sh
$ vagrant ssh master
$ sudo kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=10.244.0.0/16
```

After initializing our master node, append `--node-ip=192.168.56.10` to `KUBELET_KUBEADM_ARGS` variable in `/var/lib/kubelet/kubeadm-flags.env` file and then restart `kubelet` service: `sudo systemctl restart kubelet`.

Finally, install [Calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart) to finish setting up our master node.

## Joining worker nodes
```sh
$ vagrant ssh worker-1
$ sudo kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

Append `--node-ip=192.168.56.11` to `KUBELET_KUBEADM_ARGS` variable in `/var/lib/kubelet/kubeadm-flags.env` file and then restart `kubelet` service like we did on master node.

Do the same procedure on `worker-2`.

Now we should have a 3-node Kubernetes cluster running on our local machine:

```sh
$ vagrant ssh master
$ kubectl get node -o wide
```

```
NAME       STATUS   ROLES                  AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
master     Ready    control-plane,master   77m   v1.23.0   192.168.56.10   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   docker://20.10.11
worker-1   Ready    <none>                 52m   v1.23.0   192.168.56.11   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   docker://20.10.11
worker-2   Ready    <none>                 52m   v1.23.0   192.168.56.12   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-9-amd64   docker://20.10.11

```
