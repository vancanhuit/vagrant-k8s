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
master     Ready    control-plane   10m    v1.26.0   192.168.56.10   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-19-amd64   containerd://1.6.13
worker-1   Ready    <none>          2m1s   v1.26.0   192.168.56.11   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-19-amd64   containerd://1.6.13
worker-2   Ready    <none>          102s   v1.26.0   192.168.56.12   <none>        Debian GNU/Linux 11 (bullseye)   5.10.0-19-amd64   containerd://1.6.13
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
calico-apiserver   pod/calico-apiserver-79667464f-ndp9z           1/1     Running   0          5m40s
calico-apiserver   pod/calico-apiserver-79667464f-r55v7           1/1     Running   0          5m40s
calico-system      pod/calico-kube-controllers-67df98bdc8-cqfg6   1/1     Running   0          6m53s
calico-system      pod/calico-node-2rb98                          1/1     Running   0          2m53s
calico-system      pod/calico-node-dwrjj                          1/1     Running   0          3m12s
calico-system      pod/calico-node-nljnp                          1/1     Running   0          6m53s
calico-system      pod/calico-typha-555f9ccbb9-5pv9h              1/1     Running   0          2m46s
calico-system      pod/calico-typha-555f9ccbb9-zbcn8              1/1     Running   0          6m53s
kube-system        pod/coredns-787d4945fb-6n8jc                   1/1     Running   0          11m
kube-system        pod/coredns-787d4945fb-dv7bb                   1/1     Running   0          11m
kube-system        pod/etcd-master                                1/1     Running   0          12m
kube-system        pod/kube-apiserver-master                      1/1     Running   0          12m
kube-system        pod/kube-controller-manager-master             1/1     Running   0          12m
kube-system        pod/kube-proxy-gqn24                           1/1     Running   0          2m53s
kube-system        pod/kube-proxy-l97l2                           1/1     Running   0          11m
kube-system        pod/kube-proxy-ss45p                           1/1     Running   0          3m12s
kube-system        pod/kube-scheduler-master                      1/1     Running   0          12m
tigera-operator    pod/tigera-operator-7795f5d79b-nbmsl           1/1     Running   0          8m38s

NAMESPACE          NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
calico-apiserver   service/calico-api                        ClusterIP   10.104.28.126    <none>        443/TCP                  5m40s
calico-system      service/calico-kube-controllers-metrics   ClusterIP   10.102.54.177    <none>        9094/TCP                 5m43s
calico-system      service/calico-typha                      ClusterIP   10.105.125.137   <none>        5473/TCP                 6m53s
default            service/kubernetes                        ClusterIP   10.96.0.1        <none>        443/TCP                  12m
kube-system        service/kube-dns                          ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   12m

NAMESPACE       NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-system   daemonset.apps/calico-node       3         3         3       3            3           kubernetes.io/os=linux   6m53s
calico-system   daemonset.apps/csi-node-driver   0         0         0       0            0           kubernetes.io/os=linux   6m53s
kube-system     daemonset.apps/kube-proxy        3         3         3       3            3           kubernetes.io/os=linux   12m

NAMESPACE          NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
calico-apiserver   deployment.apps/calico-apiserver          2/2     2            2           5m40s
calico-system      deployment.apps/calico-kube-controllers   1/1     1            1           6m53s
calico-system      deployment.apps/calico-typha              2/2     2            2           6m53s
kube-system        deployment.apps/coredns                   2/2     2            2           12m
tigera-operator    deployment.apps/tigera-operator           1/1     1            1           8m38s

NAMESPACE          NAME                                                 DESIRED   CURRENT   READY   AGE
calico-apiserver   replicaset.apps/calico-apiserver-79667464f           2         2         2       5m40s
calico-system      replicaset.apps/calico-kube-controllers-67df98bdc8   1         1         1       6m53s
calico-system      replicaset.apps/calico-typha-555f9ccbb9              2         2         2       6m53s
kube-system        replicaset.apps/coredns-787d4945fb                   2         2         2       11m
tigera-operator    replicaset.apps/tigera-operator-7795f5d79b           1         1         1       8m38s
```
