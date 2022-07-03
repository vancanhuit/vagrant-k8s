# Creating a multi-node Kubernetes cluster on local machine

We need to install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/) on our machine. Make sure that our machine has enough RAM to run multiple VMs.

This quick guide is applicable from Kubernetes version `1.24+` onward. See [https://kubernetes.io/blog/2022/02/17/dockershim-faq/](https://kubernetes.io/blog/2022/02/17/dockershim-faq/) for more details about breaking changes from the Kubernetes version `1.24+`.

## Provisioning VMs with all necessary tools
```sh
$ git clone https://github.com/vancanhuit/vagrant-k8s.git
$ cd vagrant-k8s
$ vagrant up
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
NAME       STATUS   ROLES           AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION    CONTAINER-RUNTIME
master     Ready    control-plane   4m2s   v1.24.2   192.168.56.10   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-15-amd64   containerd://1.6.6
worker-1   Ready    <none>          110s   v1.24.2   192.168.56.11   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-15-amd64   containerd://1.6.6
worker-2   Ready    <none>          105s   v1.24.2   192.168.56.12   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-15-amd64   containerd://1.6.6
```

```sh
$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.56.10:6443
CoreDNS is running at https://192.168.56.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

```sh
$ kubectl get all --all-namespaces
NAMESPACE          NAME                                           READY   STATUS    RESTARTS       AGE
calico-apiserver   pod/calico-apiserver-6dd6868785-5fjl4          1/1     Running   0              2m25s
calico-apiserver   pod/calico-apiserver-6dd6868785-bx42r          1/1     Running   2 (119s ago)   2m25s
calico-system      pod/calico-kube-controllers-86dff98c45-bg66t   1/1     Running   0              4m56s
calico-system      pod/calico-node-ngv28                          1/1     Running   0              4m56s
calico-system      pod/calico-node-nlkv4                          1/1     Running   0              4m5s
calico-system      pod/calico-node-x4fff                          1/1     Running   0              4m10s
calico-system      pod/calico-typha-56f568c879-8fhv9              1/1     Running   0              3m57s
calico-system      pod/calico-typha-56f568c879-ccn2s              1/1     Running   0              4m56s
kube-system        pod/coredns-6d4b75cb6d-2c54j                   1/1     Running   0              6m6s
kube-system        pod/coredns-6d4b75cb6d-5lmwc                   1/1     Running   0              6m6s
kube-system        pod/etcd-master                                1/1     Running   0              6m8s
kube-system        pod/kube-apiserver-master                      1/1     Running   3 (69s ago)    6m8s
kube-system        pod/kube-controller-manager-master             1/1     Running   2 (59s ago)    6m8s
kube-system        pod/kube-proxy-42vs7                           1/1     Running   0              4m5s
kube-system        pod/kube-proxy-c4gcq                           1/1     Running   0              4m10s
kube-system        pod/kube-proxy-w8t4h                           1/1     Running   0              6m5s
kube-system        pod/kube-scheduler-master                      1/1     Running   2 (60s ago)    6m8s
tigera-operator    pod/tigera-operator-5dc8b759d9-dmzxp           1/1     Running   3 (59s ago)    5m6s

NAMESPACE          NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
calico-apiserver   service/calico-api                        ClusterIP   10.108.6.52      <none>        443/TCP                  2m25s
calico-system      service/calico-kube-controllers-metrics   ClusterIP   10.100.234.110   <none>        9094/TCP                 2m47s
calico-system      service/calico-typha                      ClusterIP   10.109.189.39    <none>        5473/TCP                 4m57s
default            service/kubernetes                        ClusterIP   10.96.0.1        <none>        443/TCP                  6m21s
kube-system        service/kube-dns                          ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   6m19s

NAMESPACE       NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-system   daemonset.apps/calico-node   3         3         3       3            3           kubernetes.io/os=linux   4m56s
kube-system     daemonset.apps/kube-proxy    3         3         3       3            3           kubernetes.io/os=linux   6m19s

NAMESPACE          NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
calico-apiserver   deployment.apps/calico-apiserver          2/2     2            2           2m25s
calico-system      deployment.apps/calico-kube-controllers   1/1     1            1           4m56s
calico-system      deployment.apps/calico-typha              2/2     2            2           4m56s
kube-system        deployment.apps/coredns                   2/2     2            2           6m19s
tigera-operator    deployment.apps/tigera-operator           1/1     1            1           5m6s

NAMESPACE          NAME                                                 DESIRED   CURRENT   READY   AGE
calico-apiserver   replicaset.apps/calico-apiserver-6dd6868785          2         2         2       2m25s
calico-system      replicaset.apps/calico-kube-controllers-86dff98c45   1         1         1       4m56s
calico-system      replicaset.apps/calico-typha-56f568c879              2         2         2       4m56s
kube-system        replicaset.apps/coredns-6d4b75cb6d                   2         2         2       6m6s
tigera-operator    replicaset.apps/tigera-operator-5dc8b759d9           1         1         1       5m6s
```
