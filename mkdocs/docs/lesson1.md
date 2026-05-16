# Lesson 1 — Building Your Cluster

In this lesson you will:

* Connect to your Raspberry Pi nodes
* Install K3s on the control node
* Join worker nodes to the cluster
* Verify the cluster is operational
* Explore Kubernetes resources with `kubectl`

By the end of the session, your group will have a working Kubernetes cluster running on Raspberry Pis.

---

# Connecting to Your Nodes

Each table has:

* Raspberry Pi IP addresses
* SSH login credentials
* WiFi credentials for the workshop router

Connect your laptop to:

```text
TP-Link_AP_2A5A_01
```

The access details should be available on your table.

> While connected to the workshop router, your laptop will lose internet access. You might need to have kubectl installed locally before connecting to the router s[Kubernetes commandline](https://kubernetes.io/docs/tasks/tools/)

## Verify SSH Access

Confirm you can connect to each node:

```bash
ssh chef@192.168.x.xxx
hostname
exit
```

Expected hostnames:

```text
kmaster
kworker1
kworker2
...
```

---

## Optional: Configure Host Aliases

To avoid remembering IP addresses, add entries to `/etc/hosts`:

```text
192.168.x.xxx    kmaster
192.168.x.yyy    kworker1
```

You can then connect with:

```bash
ssh chef@kmaster
```

Alternatively, configure SSH aliases in `~/.ssh/config`:

```text
Host kworker1
    HostName 192.168.x.yyy
    User chef
    IdentityFile ~/.ssh/id_ed25519
```

Then connect with:

```bash
ssh kworker1
```

---

## Test Node Connectivity

From the control node, verify worker nodes are reachable:

```bash
ssh chef@kmaster
ping -c3 192.168.x.yyy
```

---

## Troubleshooting

If a node is unreachable:

* Verify the IP address
* Check the node is powered on
* Confirm `sshd` is running
* Verify login credentials

If needed, connect the Raspberry Pi to a display and keyboard for debugging.

### Checking the Node IP Address

On the Raspberry Pi:

```bash
hostname -I
```

or

```bash
ip addr show
```

---

## Optional: Configure SSH Keys

To avoid repeatedly entering passwords:

```bash
ssh-keygen -t ed25519
ssh-copy-id chef@kmaster
```

Repeat for each node if desired.

---

# Installing K3s

K3s is a lightweight Kubernetes distribution designed for edge and resource-constrained systems such as Raspberry Pis.

We will:

1. Install K3s on the control node
2. Retrieve the cluster join token
3. Join worker nodes to the cluster

> We recommend splitting nodes between group members.

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

# Installing the Control Node

The workshop cluster is air-gapped, so installation files are already present on each node.

Internet-enabled installation commands are also shown for reference.

---

## Option 1 — With Internet Access

On `kmaster`:

```bash
curl -sfL https://get.k3s.io | sh -
```

This installer:

* downloads K3s,
* installs a systemd service,
* starts the Kubernetes control plane,
* configures `kubectl`.

---

## Option 2 — Air-Gapped Installation

On `kmaster`:

```bash
sudo -i

chmod +x /root/k3s/k3s-arm64
cp /root/k3s/k3s-arm64 /usr/local/bin/k3s

mkdir -p /var/lib/rancher/k3s/agent/images/
cp /root/k3s/k3s-airgap-images-arm64.tar \
   /var/lib/rancher/k3s/agent/images/

chmod +x /root/k3s/install.sh

INSTALL_K3S_SKIP_DOWNLOAD=true \
    /root/k3s/install.sh
```

---

# Verify the Control Node

Check the K3s service:

```bash
sudo systemctl status k3s
```

Check the node status:

```bash
sudo kubectl get nodes
```

Expected output:

```text
NAME      STATUS   ROLES           AGE   VERSION
kmaster   Ready    control-plane   30s   v1.xx.x+k3s1
```

---

## Optional: Use `kubectl` Without `sudo`

By default, K3s configures `kubectl` for root access only.

To allow non-root usage:

```bash
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

---

# Retrieve the Join Token

Worker nodes require a token to join the cluster.

On the control node:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

Share this token with the group.

---

# Installing Worker Nodes

Each worker node requires:

* the control node IP address,
* the join token.

On a worker node:

```bash
export CONTROL_NODE=192.168.x.xxx
export CONTROL_TOKEN=<token>
```

---

## Option 1 — With Internet Access

```bash
curl -sfL https://get.k3s.io | \
K3S_URL=https://$CONTROL_NODE:6443 \
K3S_TOKEN=$CONTROL_TOKEN \
sh -
```

---

## Option 2 — Air-Gapped Installation

```bash
sudo -i

chmod +x /root/k3s/k3s-arm64
cp /root/k3s/k3s-arm64 /usr/local/bin/k3s

mkdir -p /var/lib/rancher/k3s/agent/images/

cp /root/k3s/k3s-airgap-images-arm64.tar \
   /var/lib/rancher/k3s/agent/images/

chmod +x /root/k3s/install.sh

INSTALL_K3S_SKIP_DOWNLOAD=true \
K3S_URL=https://$CONTROL_NODE:6443 \
K3S_TOKEN=$CONTROL_TOKEN \
/root/k3s/install.sh
```

---

# Verify the Cluster

Back on the control node:

```bash
kubectl get nodes
```

Expected output:

```text
NAME       STATUS   ROLES           AGE
kmaster    Ready    control-plane   5m
kworker1   Ready    <none>          2m
kworker2   Ready    <none>          2m
```

All nodes should report:

```text
STATUS = Ready
```

---

# Optional: Access the Cluster From Your Laptop

Copy the Kubernetes configuration file:

```bash
scp chef@kmaster:/etc/rancher/k3s/k3s.yaml \
    ~/.kube/config-k3s
```

Edit:

```yaml
server: https://<control-node-ip>:6443
```

Then export the config:

```bash
export KUBECONFIG=~/.kube/config-k3s
```

You can now run:

```bash
kubectl get nodes
```

directly from your laptop.

For security:

```bash
chmod 600 ~/.kube/config-k3s
```

---

# Kubectl Basics

`kubectl` is the command-line interface for Kubernetes.

General syntax:

```bash
kubectl <command> <resource> [name]
```

Examples:

```bash
kubectl get nodes
kubectl describe node kworker1
```

---

# Kubernetes Namespaces

Namespaces logically separate resources within a cluster.

List all namespaces:

```bash
kubectl get namespaces
```

List all pods across namespaces:

```bash
kubectl get pods --all-namespaces
```

You should see system components such as:

* CoreDNS
* Metrics Server
* Local Path Provisioner

---

# Exploring Cluster Resources

Switch to the `kube-system` namespace:

```bash
kubectl config set-context --current --namespace=kube-system
```

View resources:

```bash
kubectl get all
```

This includes:

* Pods
* Deployments
* ReplicaSets
* Services
* Jobs

---

# Inspecting Pods

Describe a pod:

```bash
kubectl describe pod <pod-name>
```

Inspect pod YAML:

```bash
kubectl get pod <pod-name> -o yaml
```

---

# Resource Requests and Limits

Inspect resource allocations:

```bash
kubectl describe pod -l k8s-app=kube-dns
```

Edit deployment resources interactively:

```bash
kubectl edit deployment coredns
```

Or patch directly:

```bash
kubectl patch deployment coredns \
-p '{"spec":{"template":{"spec":{"containers":[{"name":"coredns","resources":{"requests":{"cpu":"120m"}}}]}}}}'
```

---

# Storage and ConfigMaps

Pods are ephemeral, so persistent data is typically stored using:

* Persistent Volumes (PV)
* Persistent Volume Claims (PVC)
* ConfigMaps

Inspect the CoreDNS configuration:

```bash
kubectl get cm coredns -o yaml
```

Inspect pod volumes:

```bash
kubectl get pod -l k8s-app=kube-dns -o yaml
```

---

# Accessing Containers

Some containers allow interactive access:

```bash
kubectl exec -it <pod-name> -- sh
```

Example:

```bash
kubectl exec -it local-path-provisioner-<hash> -- sh
```

---

# Summary

In this lesson you:

* Built a Raspberry Pi Kubernetes cluster using K3s
* Added worker nodes to the cluster
* Verified cluster health with `kubectl`
* Explored namespaces, pods, resources, and storage

You should now be comfortable:

* accessing cluster nodes,
* using `kubectl`,
* inspecting Kubernetes resources,
* managing a small Kubernetes cluster.

In the next lesson we will explore:

* networking
* ingresses
* storage
* telemetry
* CronJobs
* high availability.

---

# Acknowledgements

This workshop is delivered by the Cloud-Native SIG team with support from the Computational Abilities Knowledge Exchange Network+ (CAKE).

CAKE received funding through the UKRI Digital Research Infrastructure Programme under project reference UKRI1799.

Contributors:

* Piper Fowler-Wright — Rosalind Franklin Institute
* Lewis Sampson — STFC / DAFNI

Useful links:

* [Cloud Native SIG](https://cloudnative-sig.ac.uk/?utm_source=chatgpt.com)
* [K3s Documentation](https://docs.k3s.io/?utm_source=chatgpt.com)
* [Kubernetes Documentation](https://kubernetes.io/docs/home/?utm_source=chatgpt.com)
