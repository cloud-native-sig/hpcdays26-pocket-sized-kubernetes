# Exercise 2 — Installing K3s and creating the cluster

K3s is a lightweight Kubernetes distribution designed for edge and resource-constrained systems such as Raspberry Pis.

We will:

1. Install K3s on the control node
2. Retrieve the cluster join token
3. Join worker nodes to the cluster

> We recommend splitting responsibility of the nodes between members of your group; try to pair people with different levels or experience with the Unix Shell, with 1-3 people per node.

!!! Tip
    If you are following along after the tutorial with your own Raspberry Pis, ensure memory cgroups are enabled. Edit: `/boot/firmware/cmdline.txt` and append: `cgroup_memory=1 cgroup_enable=memory`

## Control Node: Installation

Since the tutorial clusters are air-gapped, installation files are preloaded on each node. If there are any missing files, the blue USB will contain everything needed.

For replication in your own setup, we will include internet-enabled installation options.

#### Option 1 — Air-Gapped

On `kmaster`:

```bash
sudo -i

chmod +x /root/k3s/k3s-arm64
cp /root/k3s/k3s-arm64 /usr/local/bin/k3s

mkdir -p /var/lib/rancher/k3s/agent/images/
cp /root/k3s/k3s-airgap-images-arm64.tar /var/lib/rancher/k3s/agent/images/

chmod +x /root/k3s/install.sh

INSTALL_K3S_SKIP_DOWNLOAD=true /root/k3s/install.sh
```

#### Option 2 — With Internet Access

On `kmaster`:

```bash
curl -sfL https://get.k3s.io | sh -
```

This installer:

* Downloads K3s,
* Installs a systemd service,
* Starts the Kubernetes control plane,
* Configures `kubectl`.

## Control Node: Verification

You'll see output indicating the service has started. To verify K3s is running use,

```bash
sudo systemctl status k3s
```

Check the node status:

```bash
sudo kubectl get nodes
```

You should see output similar to

```text
NAME      STATUS   ROLES           AGE   VERSION
kmaster   Ready    control-plane   30s   v1.xx.x+k3s1
```

### Optional: Use `kubectl` Without `sudo`

By default, K3s configures `kubectl` for root access only.

To allow non-root usage:

```bash
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

## Worker Nodes: Installation

Each worker node requires:

* The control node IP address,
* The join token.

### Retrieve the Join Token

The worker nodes will need a token from the control node to join the
cluster. Retrieve this with:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Share the output with everyone that is configuring a worker node!
!!! tip "Solo token transfer"
    A way to copy the token directly is to firstly copy it to `/home/chef/node-token` whilst logged into the master node and run `chown chef:chef /home/chef/node-token`. Then `scp /home/chef/node-token chef@kworker:/home/chef/` with the hostname of your desired worker node.

Now on a worker node, it is convenient to assign the variables:

```bash
export CONTROL_NODE=192.168.x.xxx
export CONTROL_TOKEN=...
```
where you should add the full token shared by whoever is on the master node.

#### Option 1 — Air-Gapped

On your desired worker  

```bash
 sudo -i

 chmod +x /root/k3s/k3s-arm64
 cp /root/k3s/k3s-arm64 /usr/local/bin/k3s

 mkdir -p /var/lib/rancher/k3s/agent/images/
 cp /root/k3s/k3s-airgap-images-arm64.tar /var/lib/rancher/k3s/agent/images/

 chmod +x /root/k3s/install.sh
 INSTALL_K3S_SKIP_DOWNLOAD=true \
  K3S_URL=https://$CONTROL_NODE:6443 \
  K3S_TOKEN=$CONTROL_TOKEN \
  /root/k3s/install.sh
```

#### Option 2 — With Internet Access

On your desired worker  

```bash
$ curl -sfL https://get.k3s.io | \
 K3S_URL=https://$CONTROL_NODE:6443 \
 K3S_TOKEN=$CONTROL_TOKEN sh -
```

## Control Node: Verify the Cluster

Back on the control node:

```bash
sudo kubectl get nodes

NAME        STATUS   ROLES              AGE     VERSION
kmaster    Ready    control-plane      5m      v1.28.5+k3s1
kworker1    Ready    <none>             2m      v1.28.5+k3s1
kworker2    Ready    <none>             1m30s   v1.28.5+k3s1
kworker3    Ready    <none>             5m13s   v1.28.5+k3s1
```

All nodes should report:

```text
STATUS = Ready
```

Note the empty ROLES. It is important to fix this. You can use the one-liner:

```bash
sudo kubectl get no -o name | grep worker | xargs -I {} sudo kubectl label {} node-role.kubernetes.io/worker=worker
```

At this point you have created a cluster. It is ready to accept Kubernetes resources and deployments. These can be done manually, as we will show over the course of the following exercises, or via GitOps. The latter is the more industry standard way of managing a cluster, using either [Flux](https://fluxcd.io/) or [ArgoCD](https://argo-cd.readthedocs.io/en/stable/). 
