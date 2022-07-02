# Creating a multi-node Kubernetes cluster on local machine

You need to install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/) on your machine. Make sure your machine has enough RAM to run multiple VMs.

This quick guide is applicable from Kubernetes `1.24+` version onward. See [https://kubernetes.io/blog/2022/02/17/dockershim-faq/](https://kubernetes.io/blog/2022/02/17/dockershim-faq/) for more details about breaking changes from Kubernetes `1.24+`.

## Provisioning VMs
```sh
$ git clone https://github.com/vancanhuit/vagrant-k8s.git
$ cd vagrant-k8s
$ vagrant up
$ vagrant reload
```

## Iniitializing master node
After all VMs are provisioned, follow this [guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/) to setup our cluster:

```sh
$ vagrant ssh master
$ sudo kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=10.244.0.0/16
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

After initializing our master node, append `--node-ip=192.168.56.10` to `KUBELET_KUBEADM_ARGS` variable in `/var/lib/kubelet/kubeadm-flags.env` file and then restart `kubelet` service: `sudo systemctl restart kubelet`.

Finally, install [Calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart) (you may choose other Pod network add-on from [here](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model) instead) to finish setting up our master node.

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
NNAME      STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
master     Ready    control-plane   11m     v1.24.2   192.168.56.10   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-13-amd64   containerd://1.6.6
worker-1   Ready    <none>          3m19s   v1.24.2   192.168.56.11   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-13-amd64   containerd://1.6.6
worker-2   Ready    <none>          2m58s   v1.24.2   192.168.56.12   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-13-amd64   containerd://1.6.6
```

```sh
$ kubectl get all --all-namespaces
```

```
NAMESPACE          NAME                                           READY   STATUS    RESTARTS        AGE
calico-apiserver   pod/calico-apiserver-5668f78797-hp59z          1/1     Running   0               8m11s
calico-apiserver   pod/calico-apiserver-5668f78797-vsm6q          1/1     Running   2 (7m30s ago)   8m11s
calico-system      pod/calico-kube-controllers-86dff98c45-nf8rd   1/1     Running   0               13m
calico-system      pod/calico-node-668fb                          1/1     Running   0               9m58s
calico-system      pod/calico-node-mfhgg                          1/1     Running   0               10m
calico-system      pod/calico-node-mrnq7                          1/1     Running   0               13m
calico-system      pod/calico-typha-6cc7d77f87-f4f8g              1/1     Running   0               13m
calico-system      pod/calico-typha-6cc7d77f87-n4pzc              1/1     Running   1 (9m12s ago)   9m55s
kube-system        pod/coredns-6d4b75cb6d-ps4d9                   1/1     Running   0               18m
kube-system        pod/coredns-6d4b75cb6d-z9r2q                   1/1     Running   0               18m
kube-system        pod/etcd-master                                1/1     Running   0               18m
kube-system        pod/kube-apiserver-master                      1/1     Running   7 (6m32s ago)   18m
kube-system        pod/kube-controller-manager-master             1/1     Running   2 (7m59s ago)   18m
kube-system        pod/kube-proxy-7wp6l                           1/1     Running   0               9m58s
kube-system        pod/kube-proxy-bszxr                           1/1     Running   0               10m
kube-system        pod/kube-proxy-gd52z                           1/1     Running   0               18m
kube-system        pod/kube-scheduler-master                      1/1     Running   2 (7m59s ago)   18m
tigera-operator    pod/tigera-operator-5dc8b759d9-lpf4p           1/1     Running   1 (8m ago)      14m

NAMESPACE          NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
calico-apiserver   service/calico-api                        ClusterIP   10.106.243.225   <none>        443/TCP                  8m11s
calico-system      service/calico-kube-controllers-metrics   ClusterIP   10.101.218.214   <none>        9094/TCP                 9m1s
calico-system      service/calico-typha                      ClusterIP   10.98.225.50     <none>        5473/TCP                 13m
default            service/kubernetes                        ClusterIP   10.96.0.1        <none>        443/TCP                  18m
kube-system        service/kube-dns                          ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   18m

NAMESPACE       NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-system   daemonset.apps/calico-node   3         3         3       3            3           kubernetes.io/os=linux   13m
kube-system     daemonset.apps/kube-proxy    3         3         3       3            3           kubernetes.io/os=linux   18m

NAMESPACE          NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
calico-apiserver   deployment.apps/calico-apiserver          2/2     2            2           8m11s
calico-system      deployment.apps/calico-kube-controllers   1/1     1            1           13m
calico-system      deployment.apps/calico-typha              2/2     2            2           13m
kube-system        deployment.apps/coredns                   2/2     2            2           18m
tigera-operator    deployment.apps/tigera-operator           1/1     1            1           14m

NAMESPACE          NAME                                                 DESIRED   CURRENT   READY   AGE
calico-apiserver   replicaset.apps/calico-apiserver-5668f78797          2         2         2       8m11s
calico-system      replicaset.apps/calico-kube-controllers-86dff98c45   1         1         1       13m
calico-system      replicaset.apps/calico-typha-6cc7d77f87              2         2         2       13m
kube-system        replicaset.apps/coredns-6d4b75cb6d                   2         2         2       18m
tigera-operator    replicaset.apps/tigera-operator-5dc8b759d9           1         1         1       14m
```
