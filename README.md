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

## Initializing control plane node
After all VMs are provisioned, follow this [guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/) to setup our cluster:

```sh
$ vagrant ssh control-plane
$ sudo kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=10.244.0.0/16
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Install [Calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart) (we may choose another Pod network add-on from [here](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-implement-the-kubernetes-networking-model) instead) to finish setting up our control plane node:

```sh
$ kubectl create -f /vagrant/tigera-operator.yaml
$ kubectl create -f /vagrant/custom-resources.yaml
```

## Joining worker nodes
```sh
$ vagrant ssh node-01
$ sudo kubeadm join 192.168.56.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```
The join command can be found after running the `kubeadm init` command above but we can find token and hash values by running the following commands on the control plane node:

```sh
$ kubeadm token list
$ openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
   openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'
```

Do the same procedure on `node-02`.

Now we should have a 3-node Kubernetes cluster running on our local machine:

```sh
$ vagrant ssh control-plane
$ kubectl get node -o wide
NAME            STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
control-plane   Ready    control-plane   5m29s   v1.29.1   192.168.56.10   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-17-amd64   containerd://1.6.27
node-01         Ready    <none>          4m40s   v1.29.1   192.168.56.11   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-17-amd64   containerd://1.6.27
node-02         Ready    <none>          4m6s    v1.29.1   192.168.56.12   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-17-amd64   containerd://1.6.27
```

```sh
$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.56.10:6443
CoreDNS is running at https://192.168.56.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

```sh
$ kubectl get all --all-namespaces
NAMESPACE          NAME                                          READY   STATUS    RESTARTS   AGE
calico-apiserver   pod/calico-apiserver-6f68b86976-przc4         1/1     Running   0          75s
calico-apiserver   pod/calico-apiserver-6f68b86976-xj2fn         1/1     Running   0          75s
calico-system      pod/calico-kube-controllers-7547d9888-975tk   1/1     Running   0          2m59s
calico-system      pod/calico-node-l4rcn                         1/1     Running   0          3m
calico-system      pod/calico-node-mxl7f                         1/1     Running   0          3m
calico-system      pod/calico-node-r5mx7                         1/1     Running   0          3m
calico-system      pod/calico-typha-5664d7c654-bzzms             1/1     Running   0          3m
calico-system      pod/calico-typha-5664d7c654-x2wfs             1/1     Running   0          2m51s
calico-system      pod/csi-node-driver-jd98c                     2/2     Running   0          3m
calico-system      pod/csi-node-driver-r25vg                     2/2     Running   0          2m59s
calico-system      pod/csi-node-driver-rw684                     2/2     Running   0          2m59s
kube-system        pod/coredns-76f75df574-46fx5                  1/1     Running   0          5m56s
kube-system        pod/coredns-76f75df574-5r5ls                  1/1     Running   0          5m56s
kube-system        pod/etcd-control-plane                        1/1     Running   0          6m12s
kube-system        pod/kube-apiserver-control-plane              1/1     Running   0          6m12s
kube-system        pod/kube-controller-manager-control-plane     1/1     Running   0          6m12s
kube-system        pod/kube-proxy-7f728                          1/1     Running   0          5m57s
kube-system        pod/kube-proxy-gqv8l                          1/1     Running   0          5m25s
kube-system        pod/kube-proxy-pl6ck                          1/1     Running   0          4m51s
kube-system        pod/kube-scheduler-control-plane              1/1     Running   0          6m12s
tigera-operator    pod/tigera-operator-55585899bf-g6r45          1/1     Running   0          3m12s

NAMESPACE          NAME                                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                  AGE
calico-apiserver   service/calico-api                        ClusterIP   10.105.29.46   <none>        443/TCP                  75s
calico-system      service/calico-kube-controllers-metrics   ClusterIP   None           <none>        9094/TCP                 76s
calico-system      service/calico-typha                      ClusterIP   10.96.31.156   <none>        5473/TCP                 3m
default            service/kubernetes                        ClusterIP   10.96.0.1      <none>        443/TCP                  6m13s
kube-system        service/kube-dns                          ClusterIP   10.96.0.10     <none>        53/UDP,53/TCP,9153/TCP   6m12s

NAMESPACE       NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-system   daemonset.apps/calico-node       3         3         3       3            3           kubernetes.io/os=linux   3m
calico-system   daemonset.apps/csi-node-driver   3         3         3       3            3           kubernetes.io/os=linux   3m
kube-system     daemonset.apps/kube-proxy        3         3         3       3            3           kubernetes.io/os=linux   6m12s

NAMESPACE          NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
calico-apiserver   deployment.apps/calico-apiserver          2/2     2            2           75s
calico-system      deployment.apps/calico-kube-controllers   1/1     1            1           2m59s
calico-system      deployment.apps/calico-typha              2/2     2            2           3m
kube-system        deployment.apps/coredns                   2/2     2            2           6m12s
tigera-operator    deployment.apps/tigera-operator           1/1     1            1           3m12s

NAMESPACE          NAME                                                DESIRED   CURRENT   READY   AGE
calico-apiserver   replicaset.apps/calico-apiserver-6f68b86976         2         2         2       75s
calico-system      replicaset.apps/calico-kube-controllers-7547d9888   1         1         1       2m59s
calico-system      replicaset.apps/calico-typha-5664d7c654             2         2         2       3m
kube-system        replicaset.apps/coredns-76f75df574                  2         2         2       5m57s
tigera-operator    replicaset.apps/tigera-operator-55585899bf          1         1         1       3m12s
```
