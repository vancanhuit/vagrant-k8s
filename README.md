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
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

After initializing our master node, append `--node-ip=192.168.56.10` to `KUBELET_KUBEADM_ARGS` variable in `/var/lib/kubelet/kubeadm-flags.env` file and then restart `kubelet` service: `sudo systemctl restart kubelet`.

Finally, install [Calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart) to finish setting up our master node.

## Joining worker nodes
```sh
$ vagrant ssh worker-1
$ sudo kubeadm join 192.168.56.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
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

```sh
$ kubectl get all --all-namespaces
```

```
NAMESPACE          NAME                                           READY   STATUS    RESTARTS        AGE
calico-apiserver   pod/calico-apiserver-5b68b6b54-gscz4           1/1     Running   2 (4m28s ago)   71m
calico-apiserver   pod/calico-apiserver-5b68b6b54-sdprf           1/1     Running   2 (4m28s ago)   71m
calico-system      pod/calico-kube-controllers-59c45ff85c-mckqw   1/1     Running   2 (4m28s ago)   73m
calico-system      pod/calico-node-f86q2                          1/1     Running   2 (4m28s ago)   73m
calico-system      pod/calico-node-msq5b                          1/1     Running   2 (4m36s ago)   69m
calico-system      pod/calico-node-zw248                          1/1     Running   2 (4m42s ago)   69m
calico-system      pod/calico-typha-77d7dfb77c-5676q              1/1     Running   4 (32s ago)     73m
calico-system      pod/calico-typha-77d7dfb77c-whrrx              1/1     Running   3 (4m42s ago)   69m
kube-system        pod/coredns-64897985d-f8px9                    1/1     Running   2 (4m23s ago)   94m
kube-system        pod/coredns-64897985d-tl2zt                    1/1     Running   2 (4m23s ago)   94m
kube-system        pod/etcd-master                                1/1     Running   2 (4m28s ago)   94m
kube-system        pod/kube-apiserver-master                      1/1     Running   2 (4m28s ago)   94m
kube-system        pod/kube-controller-manager-master             1/1     Running   2 (4m28s ago)   94m
kube-system        pod/kube-proxy-9hcnz                           1/1     Running   2 (4m28s ago)   94m
kube-system        pod/kube-proxy-gmscs                           1/1     Running   2 (4m42s ago)   69m
kube-system        pod/kube-proxy-hbgmj                           1/1     Running   2 (4m36s ago)   69m
kube-system        pod/kube-scheduler-master                      1/1     Running   2 (4m28s ago)   94m
tigera-operator    pod/tigera-operator-59d6fdcd79-wmhfh           1/1     Running   4 (32s ago)     73m

NAMESPACE          NAME                                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
calico-apiserver   service/calico-api                        ClusterIP   10.100.69.108   <none>        443/TCP                  71m
calico-system      service/calico-kube-controllers-metrics   ClusterIP   10.99.211.5     <none>        9094/TCP                 71m
calico-system      service/calico-typha                      ClusterIP   10.100.168.49   <none>        5473/TCP                 73m
default            service/kubernetes                        ClusterIP   10.96.0.1       <none>        443/TCP                  94m
kube-system        service/kube-dns                          ClusterIP   10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP   94m

NAMESPACE       NAME                                    DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR              AGE
calico-system   daemonset.apps/calico-node              3         3         3       3            3           kubernetes.io/os=linux     73m
calico-system   daemonset.apps/calico-windows-upgrade   0         0         0       0            0           kubernetes.io/os=windows   73m
kube-system     daemonset.apps/kube-proxy               3         3         3       3            3           kubernetes.io/os=linux     94m

NAMESPACE          NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
calico-apiserver   deployment.apps/calico-apiserver          2/2     2            2           71m
calico-system      deployment.apps/calico-kube-controllers   1/1     1            1           73m
calico-system      deployment.apps/calico-typha              2/2     2            2           73m
kube-system        deployment.apps/coredns                   2/2     2            2           94m
tigera-operator    deployment.apps/tigera-operator           1/1     1            1           73m

NAMESPACE          NAME                                                 DESIRED   CURRENT   READY   AGE
calico-apiserver   replicaset.apps/calico-apiserver-5b68b6b54           2         2         2       71m
calico-apiserver   replicaset.apps/calico-apiserver-697dfc8f5c          0         0         0       71m
calico-system      replicaset.apps/calico-kube-controllers-59c45ff85c   1         1         1       73m
calico-system      replicaset.apps/calico-typha-77d7dfb77c              2         2         2       73m
kube-system        replicaset.apps/coredns-64897985d                    2         2         2       94m
tigera-operator    replicaset.apps/tigera-operator-59d6fdcd79           1         1         1       73m
```
