# Exercise 2 — Installing K3s and creating the cluster

K3s is a lightweight Kubernetes distribution designed for edge and resource-constrained systems such as Raspberry Pis.

We will:

1. Install K3s on the control node
2. Retrieve the cluster join token
3. Join worker nodes to the cluster

> We recommend splitting responsibility of the nodes between members of your group; try to pair people with different levels or experience with the Unix Shell (e.g. 1-3 people max per node).

---

## Raspberry Pi Requirements

If using your own Raspberry Pis, ensure memory cgroups are enabled.

Edit:

```bash
/boot/firmware/cmdline.txt
```

Append:

```text
cgroup_memory=1 cgroup_enable=memory
```

---

## Installing the Control Node

Since the workshop cluster is air-gapped, installation files are preloaded on each node. If there are any missing files, the blue USB will contain everything needed.

But for replication in your own setup, we will include the Internet-enabled options.

**Option 1 — Air-Gapped Installation**

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

**Option 2 — With Internet Access**

On `kmaster`:

```bash
curl -sfL https://get.k3s.io | sh -
```

This installer:

* Downloads K3s,
* Installs a systemd service,
* Starts the Kubernetes control plane,
* Configures `kubectl`.

---

## Verify the Control Node

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

---

### Optional: Use `kubectl` Without `sudo`

By default, K3s configures `kubectl` for root access only.

To allow non-root usage:

```bash
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

---

## Installing Worker Nodes

Each worker node requires:

* the control node IP address,
* the join token.

---

### Retrieve the Join Token

The worker nodes will need a token from the control node to join the
cluster. Retrieve this with:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Share the output with everyone that is configuring the worker nodes!
!!! tip "Transfering the token"
    Potentially by copying it to `/home/chef/` and `chown chef:chef /home/chef/node-token`. Then `scp /home/chef/node-token chef@192.168.x.yyy:/home/chef/`

SSH into a worker node and assign these to variables:

```bash
export CONTROL_NODE=192.168.x.xxx
export CONTROL_TOKEN=<token>
```

**Option 1 — Air-Gapped Installation**

```bash
$ sudo -i

$ chmod +x /root/k3s/k3s-arm64
$ cp /root/k3s/k3s-arm64 /usr/local/bin/k3s

$ mkdir -p /var/lib/rancher/k3s/agent/images/

$ cp /root/k3s/k3s-airgap-images-arm64.tar /var/lib/rancher/k3s/agent/images/

$ chmod +x /root/k3s/install.sh

$ INSTALL_K3S_SKIP_DOWNLOAD=true \
  K3S_URL=https://$CONTROL_NODE:6443 \
  K3S_TOKEN=$CONTROL_TOKEN \
  /root/k3s/install.sh
```

---

**Option 2 — With Internet Access**

```bash
$ curl -sfL https://get.k3s.io | \
 K3S_URL=https://$CONTROL_NODE:6443 \
 K3S_TOKEN=$CONTROL_TOKEN sh -
```

---

## Verify the Cluster

Back on the control node:

```bash
$ sudo kubectl get nodes
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

But we expect the roles to be empty. To fix that we can rune the following one-liner.

```bash
sudo kubectl get no -o name | grep worker | xargs -I {} sudo kubectl label {} node-role.kubernetes.io/worker=worker
```
