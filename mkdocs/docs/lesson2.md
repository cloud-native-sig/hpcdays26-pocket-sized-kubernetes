# Lesson 2: Building Your Cluster

In this lesson, you'll install K3s on a Raspberry Pi cluster,
configuring worker nodes to join the control plane. 

## Connecting to Your Nodes

To work with the RPis, you will need the IP address for each
node and SSH login credentials, which were created when the
Raspberry Pi OS Lite was installed. Verify you can connect to each node
from your laptop, and check the local hostname:
```bash
$ ssh chef@192.168.x.xxx
$ hostname # kcontrol
$ exit 
```
For convenience, you may want to add IP-hostname pairs to 
`/etc/hosts/` on your own device:
```
/etc/hosts
----------
192.168.x.xxx    kcontrol
192.168.x.yyy    kworker1
...    
```
Then you can simply `ssh <username>@kcontrol` etc.
instead of having to remember IP addresses.

For an additional check, test you can `ping` all worker nodes
from the control node:
```bash
$ ssh chef@kcontrol
$ ping -c3 192.168.x.yyy
...
```

If you are unable to connect to a node, it may be that the IP address
has changed, `sshd` is not running, or the login credentials are
incorrect.  Connect the node to an external display to troubleshoot.

!!! tip "Static Node IP Addresses"
    You can determine a RPi's IP address by running `ip addr show`
    or `hostname -I`.
    We recommend configuring static IPs, either in you router's
    DHCP settings or on the RPi using 
    the `nmcli` or `nmtui` NetworkManager interfaces or by directly
    editing `/etc/dhcpd.conf`. See
    [PiMyLifeUp's guide](https://pimylifeup.com/raspberry-pi-static-ip-address/).

## Installing K3s

In K3s, worker nodes can be seamlessly added to the cluster using a
token generated during the installation of the cluster node. Hence,
we will install K3s on the control node before doing so on the 
workers.

We recommend splitting responsibility of 
the nodes between members of your group; try to pair
people with different levels or experience with
the Unix Shell (e.g. 1-3 people per node).

!!! warning "Pre-Installation Requirements for RPis"
    If installing K3s on your own RPi hardware, ensure memory cgroups are enabled: edit `/boot/firmware/cmdline.txt` and append `cgroup_memory=1 cgroup_enable=memory` to the existing line.

### The Control Node (Server)

K3s is installed via a single Shell script.
SSH into the control node and run:
```bash
$ curl -sfL https://get.k3s.io | sh -
```

Watch the installer:

- Download the K3s binary
- Install K3s as a systemd service
- Start the K3s server
- Configure `kubectl` to communicate with the cluster

The installation takes only 1-2 minutes. 
You'll see output indicating the service has started.
To verify K3s is running, run
```bash
$ sudo systemctl status k3s
```
and to check the node is ready,
```bash
$ sudo kubectl get nodes
```
You should see output similar to
```bash
NAME        STATUS   ROLES          AGE   VERSION
kcontrol    Ready    control-plane  30s   v1.28.5+k3s1
```

!!! tip "sudo-less kubectl (UNTESTED)"
    K3s installs `kubectl` automatically. 
    By default, it requires `sudo`. 
    To use kubectl without sudo, run:
    ```bash
    $ sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    ```
    Alternatively, if you have passwordless-sudo enabled, just
    create an `alias kubectl='sudo kubectl'`.

### Retrieve the Join Token

The worker nodes will need a token from the control node 
to join the cluster. Retrieve this with:
```bash
$ sudo cat /var/lib/rancher/k3s/server/node-token
```
Share the output with whoever is configuring the worker nodes!


### Worker Nodes (Agents)

Before installing K3s on a worker node, you will need the 
IP address or hostname of the control node and the token
created by the control node installation. SSH into a worker
node and assign these to variables:
```bash
$ export CONTROL_NODE=192.168.x.xxx
$ export CONTROL_TOKEN=<control-node-token>
``` 

The installation can then be done with a one-liner:
```bash
$ curl -sfL https://get.k3s.io | K3S_URL=https://$CONTROL_NODE:6443 K3S_TOKEN=$CONTROL_TOKEN sh -
```
where the variables `CONTROL_NODE` and `CONTROL_TOKEN` 
were defined above. This retrieves and installs the K3s
binary, and adds the worker to the cluster.

### Verify the Cluster

Back on the control node, check all nodes you 
expect have joined:
```bash
$ sudo kubectl get nodes
NAME        STATUS   ROLES              AGE     VERSION
kcontrol    Ready    control-plane      5m      v1.28.5+k3s1
kworker1    Ready    <none>             2m      v1.28.5+k3s1
kworker2    Ready    <none>             1m30s   v1.28.5+k3s1
kworker3    Ready    <none>             5m13s   v1.28.5+k3s1
```

!!! tip "kubectl from your laptop (UNTESTED)"
    If you have `kubectl` installed on your own device, you can copy
    `/etc/rancher/k3s/k3s.yaml` from the control node
    to  `~/.kube/config-k3s` on your device, edit 
    `server: https://<control-node-ip/hostanme>:6443`
    to point to the control node, and 
    `export KUBECONFIG=~/.kube/config-k3s`. You should then
    be able run `kubectl` commands against the cluster
    without having to SSH into the control node.

### Kubectl Basics

`kubectl` is the main command that allows you to interact with
a Kubernetes cluster through the server API. The general
syntax is:
```bash
$ kubectl <command> <type> [name] [flags]
```
where `<command>` specifies the action to perform, `<type>` is the
type of Kubernetes *resource* (e.g., nodes, pods, deployments), 
`[name]` is the optional name of the resource, and `[flags]` are optional
parameters.

 For example,
to list all nodes on the cluster,
```bash
$ kubectl get nodes
```
and get detailed information of a particular node,
```bash
$ kubectl describe node kworker1
```
We'll be seeing the power of `kubectl` when it comes to 
application deployments in the next lesson.

### Kubernetes Namespaces
Namespaces are logical divisions or groupings of resources within
a cluster.  This allows you to separate, for example, different
applications or different deployments of an application such as 
`dev` and `prod`. 

By default, `kubectl` refers to the `default` namespace. Since we have
not deployed any applications in this (or any other) namespace,
`kubectl get deployments` and `kubectl get pods` will not return
anything.  However, there are still a number of pods running essential
*system* processes in system namespaces:
```bash
$ kubectl get pods --all-namespaces
```
Which of these can you match to Kubernetes services from 
the [Introduction](./introduction.md#architecture-overview)?
