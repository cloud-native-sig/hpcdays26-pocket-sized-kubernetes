# Lesson 1 — Building Your Cluster

In this lesson we’ll assemble a small Kubernetes cluster using Raspberry Pis and K3s. By the end of the session, each group should have a functioning multi-node cluster that you can interact with using kubectl.

Along the way we’ll:

* connect to the Raspberry Pis over SSH,
* install a Kubernetes control plane,
* join worker nodes to the cluster,
* and take a first look at the resources Kubernetes creates behind the scenes.

This session is intentionally hands-on, so expect to spend most of the time in the terminal exploring the cluster directly.
---

# Connecting to Your Nodes

Each table has a note with:

* Raspberry Pi IP addresses
* SSH login credentials
* WiFi credentials for the workshop router

You will also need to connect to our Router - `TP-Link_AP_2A5A_01`

> While connected to the workshop router, your laptop will lose internet access. You might need to have kubectl installed locally before connecting [Kubernetes commandline](https://kubernetes.io/docs/tasks/tools/)

## Verify SSH Access

Once you have connected to the route, as a group you need to confirm you can connect to each node:

```bash
ssh chef@192.168.x.xxx
hostname
exit
```
---

## Test Node Connectivity

From the control node, verify worker nodes are reachable:

```bash
ssh chef@kmaster
ping -c3 192.168.x.yyy
```

---
## Optional: Configure Host Aliases

For convenience, you may want to add IP-hostname pairs to 
`/etc/hosts/` on your own device:

```text
192.168.x.xxx    kmaster
192.168.x.yyy    kworker1
```

Then you can simply `ssh <username>@kmaster` etc. instead of having 
to remember all the IP addresses.

Alternatively, configure SSH aliases in `~/.ssh/config`, e.g.

```text
Host kworker1
    HostName 192.168.x.yyy
    User chef
    IdentityFile ~/.ssh/id_ed25519
```

Then connect with `ssh kworker1`

---



## Optional: Configure SSH Keys

To avoid repeatedly entering passwords:

```bash
ssh-keygen -t ed25519
ssh-copy-id chef@kmaster
```

Repeat for each node if desired.

---
## Optional: Troubleshooting

We should have configured static IPs through our router's DHCP settings.
But, if a node is unreachable we will need to:

* Verify the IP address
* Check the node is powered on
* Confirm `sshd` is running
* Configured a static IPs using `nmcli` or `nmtui`.

If needed, ask one of the course facilitators to help by connecting the Raspberry Pi to a display and keyboard for debugging.
---
# Installing K3s and creating the cluster

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

---

### Option 1 — Air-Gapped Installation

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
### Option 2 — With Internet Access

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
---
### Option 1 — Air-Gapped Installation

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
### Option 2 — With Internet Access

```bash
curl -sfL https://get.k3s.io | \
K3S_URL=https://$CONTROL_NODE:6443 \
K3S_TOKEN=$CONTROL_TOKEN \
sh -
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

`sudo kubectl get no -o name | grep worker | xargs -I {} sudo kubectl label {} node-role.kubernetes.io/worker=worker`


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

We have already seen that `kubectl` is the command-line interface for Kubernetes. Now we will explore the basics of how the tool can be used; 

The general syntax is:

```bash
$ kubectl <command> <type> [name] [flags]
```
where `<command>` specifies the action to perform, `<type>` is the
type of Kubernetes *resource* (e.g., nodes, pods, deployments), 
`[name]` is the optional name of the resource, and `[flags]` are 
optional parameters.

Examples:

```bash
kubectl get nodes
kubectl describe node kworker1
```

---

## Kubernetes Namespaces

Namespaces logically separate resources within a cluster. This allows you to separate applications or different deployments of an application such as `dev` and `prod`. 

List all namespaces:

```bash
kubectl get namespaces
```

There are  a number of pods running essential *system* processes in the `kube-system` namespace:
```bash
$ kubectl get pods --all-namespaces
```
You can match these to services from the Kubernetes [Introduction](./introduction.md#architecture-overview)?

---

## Exploring Cluster Resources

By default, `kubectl` refers to the `default` namespace. Since we have not deployed any applications in this namespace, `kubectl get deployments` and `kubectl get pods` will not return anything. 

Switch to the `kube-system` namespace:

```bash
kubectl config set-context --current --namespace=kube-system
```

View *all* resources:

```bash
kubectl get all
```

This includes:

* Pods
* Deployments
* ReplicaSets
* Services
* Jobs

> `kubectl get all` does not quite show all the resources, but it does highlight the main ones.

---

### Resource Requests and Limits

Still using `kubectl` we can investigate exactly how and what is running on the cluster at this point.

### Inspecting Pods

We can start by inspecting the pods we have found in the `kube-system` namespace. 

Describe any pod:

```bash
kubectl describe pod <pod-name>
```

Inspect a pod manifest output to YAML:

```bash
kubectl get pod <pod-name> -o yaml
```

To view the resources that are being used by these pods we can 
inspect the pod itself.

```bash
kubectl get pod -o json -l k8s-app=kube-dns | jq -r '.items[0].status.containerStatuses[].allocatedResources'
kubectl get pod -o json -l k8s-app=kube-dns | jq -r '.items[0].status.containerStatuses[].resources.limits'
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

### Storage and ConfigMaps

Pods are ephemeral, so persistent data is typically stored using:

* Persistent Volumes (PV)
* Persistent Volume Claims (PVC)
* ConfigMaps

Lets take a look at those now. Inspect the CoreDNS configuration:

```bash
kubectl get cm coredns -o yaml
```

Check the pod manifest for volumes and volumemounts:

```bash
kubectl get pod -l k8s-app=kube-dns -o yaml| grep -i volumes -A 32
```

The above grabs a specific part of the yaml definition for the DNS 
pods, but feel free to inspect further by removing the `grep` 
command.

You should see something like the following. 
```yaml
    - configMap:
        defaultMode: 420
        items:
        - key: Corefile
          path: Corefile
        - key: NodeHosts
          path: NodeHosts
        name: coredns
      name: config-volume
```
We can see that the DNS pod use the existing configmap to read in 
specifications for running the pod itself.

---

### Accessing Containers

For some pods, their containers allow interactive access:

```bash
kubectl exec -it <pod-name> -- sh
```

Example:

```bash
kubectl exec -it local-path-provisioner-<hash> -- sh
```
From here you can view the mounted volumes. See if you can find this where the configmap has been mounted, and where the data came from.

---

# Summary

This lesson has focussed on getting the K3s cluster setup and working
for each group, you have:
* Built a Raspberry Pi Kubernetes cluster using K3s
* Added worker nodes to the cluster
* Verified cluster health with `kubectl`
* Explored namespaces, pods, resources, and storage

By the end of the session you should be a comfortable:
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

Documentation: 
* [Cloud Native SIG](https://cloudnative-sig.ac.uk/?utm_source=chatgpt.com)
* [K3s Documentation](https://docs.k3s.io/?utm_source=chatgpt.com)
* [Kubernetes Documentation](https://kubernetes.io/docs/home/?utm_source=chatgpt.com)

Links:
* [DAFNI](https://dafni.ac.uk/) 
* [CAKE](https://www.cake.ac.uk/)
* [RFI ARC](https://www.rfi.ac.uk/focus/platforms/advanced-research-computing/)