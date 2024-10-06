# Creating a multi-node Kubernetes cluster on local machine

Install latest version of [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/) on your machine. Make sure that your machine has enough RAM to run multiple VMs.

## Provisioning VMs with all necessary tools
```sh
$ git clone https://github.com/vancanhuit/vagrant-k8s.git
$ cd vagrant-k8s
$ vagrant up
$ vagrant reload
```

## Initializing control plane node
After all VMs are provisioned, follow this [guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/) to setup a cluster:

```sh
$ vagrant ssh control-plane
```
```sh
$ sudo kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=10.244.0.0/16
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Install [Calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart) CNI plugin (we can find a list of network plugins [here](https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy)) to finish setting up the control plane node:

```sh
$ kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
$ kubectl create -f /vagrant/conf/custom-resources.yaml
```

## Joining worker nodes
```sh
$ vagrant ssh node-01
```
```sh
$ sudo kubeadm join 192.168.56.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```
The join command can be found after running the `kubeadm init` command but the token and hash values can be found by running the following commands on the control plane node:

```sh
$ kubeadm token list
$ openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
   openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'
```

Do the same procedure on `node-02`.

Now we should have a 3-node Kubernetes cluster running on local machine:

```sh
$ vagrant ssh control-plane
```
```sh
$ kubectl get node -o wide
NAME            STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
control-plane   Ready    control-plane   8m32s   v1.30.5   192.168.56.10   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-26-amd64   containerd://1.6.36
node-01         Ready    <none>          6m6s    v1.30.5   192.168.56.11   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-26-amd64   containerd://1.6.36
node-02         Ready    <none>          5m34s   v1.30.5   192.168.56.12   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-26-amd64   containerd://1.6.36
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
calico-apiserver   pod/calico-apiserver-58588ff69-2784s           1/1     Running   0          5m44s
calico-apiserver   pod/calico-apiserver-58588ff69-4bst5           1/1     Running   0          5m44s
calico-system      pod/calico-kube-controllers-6b5fc6786d-zn6hm   1/1     Running   0          8m15s
calico-system      pod/calico-node-2hhws                          1/1     Running   0          8m15s
calico-system      pod/calico-node-c74cq                          1/1     Running   0          7m44s
calico-system      pod/calico-node-cznvd                          1/1     Running   0          7m12s
calico-system      pod/calico-typha-6db85d4766-jpdn8              1/1     Running   0          8m15s
calico-system      pod/calico-typha-6db85d4766-wr8fx              1/1     Running   0          7m10s
calico-system      pod/csi-node-driver-4r5sw                      2/2     Running   0          8m15s
calico-system      pod/csi-node-driver-lglh6                      2/2     Running   0          7m44s
calico-system      pod/csi-node-driver-mczqr                      2/2     Running   0          7m12s
kube-system        pod/coredns-55cb58b774-6t8fg                   1/1     Running   0          9m53s
kube-system        pod/coredns-55cb58b774-m4xlx                   1/1     Running   0          9m53s
kube-system        pod/etcd-control-plane                         1/1     Running   0          10m
kube-system        pod/kube-apiserver-control-plane               1/1     Running   0          10m
kube-system        pod/kube-controller-manager-control-plane      1/1     Running   0          10m
kube-system        pod/kube-proxy-fl7x7                           1/1     Running   0          7m44s
kube-system        pod/kube-proxy-j5b7p                           1/1     Running   0          7m12s
kube-system        pod/kube-proxy-tvzg4                           1/1     Running   0          9m54s
kube-system        pod/kube-scheduler-control-plane               1/1     Running   0          10m
tigera-operator    pod/tigera-operator-576646c5b6-8thq6           1/1     Running   0          9m19s

NAMESPACE          NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
calico-apiserver   service/calico-api                        ClusterIP   10.96.212.147    <none>        443/TCP                  5m44s
calico-system      service/calico-kube-controllers-metrics   ClusterIP   None             <none>        9094/TCP                 7m9s
calico-system      service/calico-typha                      ClusterIP   10.110.126.136   <none>        5473/TCP                 8m15s
default            service/kubernetes                        ClusterIP   10.96.0.1        <none>        443/TCP                  10m
kube-system        service/kube-dns                          ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP   10m

NAMESPACE       NAME                             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
calico-system   daemonset.apps/calico-node       3         3         3       3            3           kubernetes.io/os=linux   8m15s
calico-system   daemonset.apps/csi-node-driver   3         3         3       3            3           kubernetes.io/os=linux   8m15s
kube-system     daemonset.apps/kube-proxy        3         3         3       3            3           kubernetes.io/os=linux   10m

NAMESPACE          NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
calico-apiserver   deployment.apps/calico-apiserver          2/2     2            2           5m44s
calico-system      deployment.apps/calico-kube-controllers   1/1     1            1           8m15s
calico-system      deployment.apps/calico-typha              2/2     2            2           8m15s
kube-system        deployment.apps/coredns                   2/2     2            2           10m
tigera-operator    deployment.apps/tigera-operator           1/1     1            1           9m19s

NAMESPACE          NAME                                                 DESIRED   CURRENT   READY   AGE
calico-apiserver   replicaset.apps/calico-apiserver-58588ff69           2         2         2       5m44s
calico-system      replicaset.apps/calico-kube-controllers-6b5fc6786d   1         1         1       8m15s
calico-system      replicaset.apps/calico-typha-6db85d4766              2         2         2       8m15s
kube-system        replicaset.apps/coredns-55cb58b774                   2         2         2       9m53s
tigera-operator    replicaset.apps/tigera-operator-576646c5b6           1         1         1       9m19s
```

## Ingress NGINX controller

[https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#via-the-host-network](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#via-the-host-network).

```sh
$ vagrant ssh control-plane
```
```sh
$ kubectl label node node-01 node-role.kubernetes.io/edge=""
$ kubectl label node node-01 node-role.kubernetes.io/node=""
$ kubectl label node node-02 node-role.kubernetes.io/node=""

$ kubectl get node
NAME            STATUS   ROLES           AGE   VERSION
control-plane   Ready    control-plane   22m   v1.30.5
node-01         Ready    edge,node       19m   v1.30.5
node-02         Ready    node            19m   v1.30.5

$ kubectl create -f /vagrant/conf/ingress-nginx-controller.yaml
$ kubectl -n ingress-nginx get all
NAME                                       READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create-ngqwv   0/1     Completed   0          16s
pod/ingress-nginx-admission-patch-zql4n    0/1     Completed   1          16s
pod/ingress-nginx-controller-np625         1/1     Running     0          16s

NAME                                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/ingress-nginx-controller-admission   ClusterIP   10.108.228.71   <none>        443/TCP   16s

NAME                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                          AGE
daemonset.apps/ingress-nginx-controller   1         1         1       1            1           kubernetes.io/os=linux,node-role.kubernetes.io/edge=   16s

NAME                                       STATUS     COMPLETIONS   DURATION   AGE
job.batch/ingress-nginx-admission-create   Complete   1/1           4s         16s
job.batch/ingress-nginx-admission-patch    Complete   1/1           4s         16s
```

```sh
$ vagrant ssh node-01
```
```sh
$ sudo ufw allow http
$ sudo ufw allow https
```

## Example application deployment

```sh
$ vagrant ssh control-plane
```
```sh
$ kubectl create -f /vagrant/conf/usage.yaml
$ kubectl get all
$ kubectl get ingress
NAME              CLASS    HOSTS   ADDRESS         PORTS   AGE
example-ingress   <none>   *       192.168.56.11   80      67s

$ curl -s http://192.168.56.11/foo/hostname | xargs
$ curl -s http://192.168.56.11/bar/hostname | xargs
```

