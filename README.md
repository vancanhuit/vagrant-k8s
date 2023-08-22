# Creating a multi-node Kubernetes cluster on local machine

We need to install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/) on our machine. Make sure that our machine has enough RAM to run multiple VMs.

This quick guide is applicable from Kubernetes version `1.24+` onward. See [https://kubernetes.io/blog/2022/02/17/dockershim-faq/](https://kubernetes.io/blog/2022/02/17/dockershim-faq/) for more details about breaking changes from the Kubernetes version `1.24+`.

## Provisioning VMs with all necessary tools
```sh
$ git clone https://github.com/vancanhuit/vagrant-k8s.git
$ cd vagrant-k8s
$ vagrant up
# IMPORTANT: Disable swap on each node before reloading.
# Run `vagrant ssh <node>` where node is `master`, `worker-1` or `worker-2` to access each node.
# We MUST disable swap in order for the kubelet to work properly:
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin.
# Simply comment out the swap entry in `/etc/fstab` file.
$ vagrant reload
```

## Initializing master node
After all VMs are provisioned, follow this [guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/) to setup our cluster:

```sh
$ vagrant ssh master
$ sudo kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=10.244.0.0/16
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Install [Calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart) (we may choose another Pod network add-on from [here](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model) instead) to finish setting up our master node:

```sh
$ kubectl create -f /vagrant/tigera-operator.yaml
$ kubectl create -f /vagrant/custom-resources.yaml
```

## Joining worker nodes
```sh
$ vagrant ssh worker-1
$ sudo kubeadm join 192.168.56.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```
The join command can be found after running the `kubeadm init` command above but we can find token and hash values by running the following commands on the master node:

```sh
$ kubeadm token list
$ openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
   openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'
```

Do the same procedure on `worker-2`.

Now we should have a 3-node Kubernetes cluster running on our local machine:

```sh
$ vagrant ssh master
$ kubectl get node -o wide
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
master     Ready    control-plane   4m25s   v1.28.0   192.168.56.10   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-11-amd64   containerd://1.7.3
worker-1   Ready    <none>          2m6s    v1.28.0   192.168.56.11   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-11-amd64   containerd://1.7.3
worker-2   Ready    <none>          112s    v1.28.0   192.168.56.12   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-11-amd64   containerd://1.7.3
```

```sh
$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.56.10:6443
CoreDNS is running at https://192.168.56.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

```sh
$ kubectl get all --all-namespaces
NAMESPACE          NAME                                           READY   STATUS    RESTARTS   AGE
calico-apiserver   pod/calico-apiserver-7f6fbdb8bf-n698c          1/1     Running   0          2m55s
calico-apiserver   pod/calico-apiserver-7f6fbdb8bf-zh6pn          1/1     Running   0          2m55s
calico-system      pod/calico-kube-controllers-58659d6465-2bt55   1/1     Running   0          3m20s
calico-system      pod/calico-node-59ltv                          1/1     Running   0          2m42s
calico-system      pod/calico-node-d86qm                          1/1     Running   0          2m28s
calico-system      pod/calico-node-ww9jx                          1/1     Running   0          3m20s
calico-system      pod/calico-typha-786b5694db-g64rl              1/1     Running   0          2m25s
calico-system      pod/calico-typha-786b5694db-lvspv              1/1     Running   0          3m20s
calico-system      pod/csi-node-driver-gstcv                      2/2     Running   0          2m42s
calico-system      pod/csi-node-driver-k4v7f                      2/2     Running   0          3m20s
calico-system      pod/csi-node-driver-sgn6s                      2/2     Running   0          2m28s
kube-system        pod/coredns-5dd5756b68-mbk6f                   1/1     Running   0          4m44s
kube-system        pod/coredns-5dd5756b68-xkpw7                   1/1     Running   0          4m44s
kube-system        pod/etcd-master                                1/1     Running   2          4m59s
kube-system        pod/kube-apiserver-master                      1/1     Running   2          4m57s
kube-system        pod/kube-controller-manager-master             1/1     Running   2          4m57s
kube-system        pod/kube-proxy-dhgm4                           1/1     Running   0          2m42s
kube-system        pod/kube-proxy-pxd7f                           1/1     Running   0          2m28s
kube-system        pod/kube-proxy-qwzpk                           1/1     Running   0          4m45s
kube-system        pod/kube-scheduler-master                      1/1     Running   2          4m57s
tigera-operator    pod/tigera-operator-94d7f7696-jcmmd            1/1     Running   0          3m58s

NAMESPACE          NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
calico-apiserver   service/calico-api                        ClusterIP   10.101.116.217   <none>        443/TCP                  2m55s
calico-system      service/calico-kube-controllers-metrics   ClusterIP   None             <none>        9094/TCP                 3m3s
calico-system      service/calico-typha                      ClusterIP   10.99.46.233     <none>        5473/TCP                 3m20s
default            service/kubernetes                        ClusterIP   10.96.0.1        <none>        443/TCP                  4m59s
kube-system        service/kube-dns                          ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   4m57s

NAMESPACE       NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-system   daemonset.apps/calico-node       3         3         3       3            3           kubernetes.io/os=linux   3m20s
calico-system   daemonset.apps/csi-node-driver   3         3         3       3            3           kubernetes.io/os=linux   3m20s
kube-system     daemonset.apps/kube-proxy        3         3         3       3            3           kubernetes.io/os=linux   4m57s

NAMESPACE          NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
calico-apiserver   deployment.apps/calico-apiserver          2/2     2            2           2m55s
calico-system      deployment.apps/calico-kube-controllers   1/1     1            1           3m20s
calico-system      deployment.apps/calico-typha              2/2     2            2           3m20s
kube-system        deployment.apps/coredns                   2/2     2            2           4m57s
tigera-operator    deployment.apps/tigera-operator           1/1     1            1           3m58s

NAMESPACE          NAME                                                 DESIRED   CURRENT   READY   AGE
calico-apiserver   replicaset.apps/calico-apiserver-7f6fbdb8bf          2         2         2       2m55s
calico-system      replicaset.apps/calico-kube-controllers-58659d6465   1         1         1       3m20s
calico-system      replicaset.apps/calico-typha-786b5694db              2         2         2       3m20s
kube-system        replicaset.apps/coredns-5dd5756b68                   2         2         2       4m45s
tigera-operator    replicaset.apps/tigera-operator-94d7f7696            1         1         1       3m58s
```
