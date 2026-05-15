# Lesson 1: Building Your Cluster

In this lesson, you'll install K3s on a Raspberry Pi cluster,
configuring worker nodes to join the control plane. We will then
deploy some basic resources onto the cluster and inspect them.

## Connecting to Your Nodes

To work with the RPis, you will need the IP address for each
node and the basic SSH login credentials, which were created when the
Raspberry Pi OS Lite was installed. 

You will also need to connect to our Router - TP-Link_AP_2A5A_01. The 
access code, IPs, and SSH login credentials should be on your table.

!!! tip "kubectl from your laptop"
    While connected to the router, you wont have internet access on 
    your PC. For later use, you may want to install kubectl locally.
    [Kubernetes commandline](https://kubernetes.io/docs/tasks/tools/)

Please verify you can connect to each node in your cluster from your
laptop, and check the local hostname:
```bash
$ ssh chef@192.168.x.xxx
$ hostname # kmaster
$ exit 
```

If you are following this workshop in your own setup, you will need 
your own form of compute. Either using cloud nodes or your own RPi.

### Hosts
For convenience, you may want to add IP-hostname pairs to 
`/etc/hosts/` on your own device:
```
/etc/hosts
----------
192.168.x.xxx    kmaster
192.168.x.yyy    kworker1
...    
```
Then you can simply `ssh <username>@kmaster` etc. instead of having 
to remember all the IP addresses.

Or you can create entries in your SSH config, ~/.ssh/config.

```
Host kworker3
    HostName 192.168.x.yyy
    User chef
    IdentityFile /home/dkv26262/.ssh/<local_ssh_priv_key> 
```
and use `ssh@kworker3`.

### Pings 
For an additional check, test you can `ping` all worker nodes
in your cluster from the control node:
```bash
$ ssh chef@kmaster
$ ping -c3 192.168.x.yyy
...
```
### Troubleshooting 
We should have configured static IPs for our router's DHCP settings.
But, if you are unable to connect to a node, it may be that the IP 
address has changed, `sshd` is not running, or the login credentials
are incorrect. Connect the node to an external display to 
troubleshoot.

!!! tip "Static Node IP Addresses"
    You can determine a RPi's IP address by running `ip addr show` or
    `hostname -I`. This should be configured as a static IPs using 
    the `nmcli` or `nmtui` NetworkManager interfaces on the RPi. See 
    [PiMyLifeUp's guide](https://pimylifeup.com/raspberry-pi-static-ip-address/), 
    or ask Lewis for help.

### Setup ssh keys (optional)
If you dislike entering password consistently, you can setup ssh key
access like follows.
```
ssh-keygen -t ed25519
ssh-copy-id  chef@kmaster # for any machine
```

## Installing K3s

In K3s, worker nodes can be seamlessly added to the cluster using a
token generated during the installation of the cluster node. Hence,
we will install K3s on the control node before doing so on the 
workers.

We recommend splitting responsibility of the nodes between members of
your group; try to pair people with different levels or experience 
with the Unix Shell (e.g. 1-3 people max per node).

!!! warning "Pre-Installation Requirements for RPis"
    If installing K3s on your own RPi hardware, ensure memory cgroups
    are enabled: edit `/boot/firmware/cmdline.txt` and append 
    `cgroup_memory=1 cgroup_enable=memory` to the existing line.

### The Control Node (Server)

Since we do not have internet access for the RPi's, we have copied the
binaries onto the machines locally. This will be the same for various 
manifests. But for replication in your own setup, we will include the 
WWW options. 

#### With internet 
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

#### Without internet 
```
sudo -i # Or otherwise as root
chmod +x /root/k3s/k3s-arm64  # k3s executable
cp /root/k3s/k3s-arm64 /usr/local/bin/k3s 
mkdir -p /var/lib/rancher/k3s/agent/images/  # Prepare k3s images
cp /root/k3s/k3s-airgap-images-arm64.tar /var/lib/rancher/k3s/agent/images/
chmod +x /root/k3s/install.sh
INSTALL_K3S_SKIP_DOWNLOAD=true /root/k3s/install.sh # Run k3s install with local images
```
#### Check install
The installation takes only 1-2 minutes. You'll see output indicating 
the service has started. To verify K3s is running use,

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
kmaster    Ready    control-plane  30s   v1.35.5+k3s1
```

!!! tip "sudo-less kubectl"
    K3s installs `kubectl` automatically, but as root. So by default 
    it requires `sudo`. To use kubectl without sudo, run:
    ```bash
    $ sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    ```
    Alternatively, if you have passwordless-sudo enabled, just
    create an `alias kubectl='sudo kubectl'`.

### Retrieve the Join Token

The worker nodes will need a token from the control node to join the 
cluster. Retrieve this with:
```bash
$ sudo cat /var/lib/rancher/k3s/server/node-token
```
Share the output with everyone that is configuring the worker nodes!
!!! tip "Transfering the token"
    Potentially by copying it to `/home/chef/` and 
    `chown chef:chef /home/chef/node-token`. Then you can use secure copy
    `scp /home/chef/node-token chef@192.168.x.yyy:/home/chef/`

### Worker Nodes (Agents)

Before installing K3s on a worker node, you will need the IP address 
of the control node and the token created by the control node 
installation. SSH into a worker node and assign these to variables:
```bash
$ export CONTROL_NODE=192.168.x.xxx
$ export CONTROL_TOKEN=<control-node-token>
``` 

#### With internet
The installation can then be done with a one-liner:
```bash
$ curl -sfL https://get.k3s.io | K3S_URL=https://$CONTROL_NODE:6443 K3S_TOKEN=$CONTROL_TOKEN sh -
```
where the variables `CONTROL_NODE` and `CONTROL_TOKEN` were defined 
above. This retrieves and installs the K3s binary, and adds the 
worker to the cluster.

#### Without internet
```
sudo -i  # Or otherwise as root
chmod +x /root/k3s/k3s-arm64
cp /root/k3s/k3s-arm64 /usr/local/bin/k3s
mkdir -p /var/lib/rancher/k3s/agent/images/
cp /root/k3s/k3s-airgap-images-arm64.tar /var/lib/rancher/k3s/agent/images/
chmod +x /root/k3s/install.sh
# Run k3s worker install with local images using token and IP provided. 
INSTALL_K3S_SKIP_DOWNLOAD=true K3S_URL=https://$CONTROL_NODE:6443 K3S_TOKEN=$CONTROL_TOKEN /root/k3s/install.sh 
```
### Verify the Cluster

Back on the control node, check all nodes you expect have joined:

```bash
$ sudo kubectl get nodes
NAME        STATUS   ROLES              AGE     VERSION
kmaster    Ready    control-plane      5m      v1.28.5+k3s1
kworker1    Ready    <none>             2m      v1.28.5+k3s1
kworker2    Ready    <none>             1m30s   v1.28.5+k3s1
kworker3    Ready    <none>             5m13s   v1.28.5+k3s1
```

!!! tip "kubectl from your laptop"
    If you have `kubectl` installed on your own device, you can copy
    `/etc/rancher/k3s/k3s.yaml` from the control node to  
    `~/.kube/config-k3s` on your device, edit 
    `server: https://<control-node-ip/hostname>:6443`
    to point to the control node, and 
    `export KUBECONFIG=~/.kube/config-k3s`. You should then be able 
    run `kubectl` commands against the cluster without having to SSH 
    into the control node.
    
For security reasons it is good practice to ensure the files 
permissions are limited. `chmod 600 ~/.kube/config-k3s` 

### Kubectl Basics

`kubectl` is the main command that allows you to interact with a 
Kubernetes cluster through the server API. The general syntax is:

```bash
$ kubectl <command> <type> [name] [flags]
```
where `<command>` specifies the action to perform, `<type>` is the
type of Kubernetes *resource* (e.g., nodes, pods, deployments), 
`[name]` is the optional name of the resource, and `[flags]` are 
optional parameters.

For example, to list all nodes on the cluster,

```bash
$ kubectl get nodes
```
and get detailed information of a particular node,
```bash
$ kubectl describe node kworker1
```

#### Kubernetes Namespaces
Namespaces are logical divisions or groupings of resources within a 
cluster. This allows you to separate, for example, different 
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

#### Resources and resource management

You can see more resources by moving your context to the 
`kube-system` namespace with:
```
kubectl config set-context --namespace=kube-system --current
kubectl get all
```
Now we can see more details on exactly what is being run on the 
cluster, such as; replicasets, jobs, deployments, etc. 

To view the resources that are being used by these pods we can 
inspect the pod itself.

```
kubectl get pod -o json -l k8s-app=kube-dns | jq -r '.items[0].status.containerStatuses[].allocatedResources'
kubectl get pod -o json -l k8s-app=kube-dns | jq -r '.items[0].status.containerStatuses[].resources.limits'
```

You can also inspect pods by getting a detailed report using:

```
kubectl describe pod -l k8s-app=kube-dns
```

This will give information about the status of the pod, recent events
and some of the pod specifications. 

You can set the resource limits and requests in the original manifest 
or interactive by editing the existing deployments template 
specification.

```
kubectl edit deployment coredns
```
Or
```
kubectl patch deployment coredns -p '{"spec": { "template": {"spec": {"containers": [{"name": "coredns","resources": {"requests": {"cpu": "120m"}}}]}}}}'
```

#### Pod Storage, ConfigMaps and PVCs

Within Kubernetes pods are ephemeral, so most storage that needs to
persist is held in Persistent Volumes and loaded as volumes into the
pod. 

With our systems only pods, we can inspect this information too. 
```
kubectl get pod -o yaml -l k8s-app=kube-dns | grep -i volumes -A 32
```
The above grabs a specific part of the yaml definition for the DNS 
pods, but feel free to inspect further by removing the `grep` 
command.

You should see something like the following. 
```
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
We can see that the DNS pod uses existing configmaps to read in 
specifications for running the pod itself. We can inspect the 
contents of the config map directly, again using `kubectl`.

```
kubectl get cm -o yaml coredns
```

This configmap is then mapped directly to the RPi's memory within the
pod and will be used while the container is created. For some pods, 
this can be interacted with using `kubectl exec -it `. The core DNS
pod does not have this available, but your local-path-provisioner can.

```
kubectl exec -it local-path-provisioner-<your-hash> -- sh
ls -la
```

## Summary

This lesson has focussed on getting the K3s cluster setup and working
for each group. Using the air-gapped install we have prepared the 
master node and added in each worker. Following this multiple 
resources are created on the cluster so we have had a look at these,
and what the command line interface, `kubectl` can be useful for. We
used storage and compute resources as examples for exploring the pods
, but we will have a more technical look in the next lesson.

By the end of the session you should have a comfortable understanding
of how you could create a kubernetes cluster with a similar setup, and
be able to access the entire cluster from your local computer. 

In the next session we will take a deeper dive into what can 
kubernetes do and investigate important topics like; Networking, 
Ingresses, CronJobs, more Storage details, Telemetry and High 
Availability. 

Any questions please find Lewis and Piper, or reach out to the 
Cloud Native Significent Interest Group. 
[e-mail](cloudnative-sig@jiscmail.ac.uk)
[Website](https://cloudnative-sig.ac.uk/)

## Acknowledgements 

This workshop is delivered by the Cloud-Native SIG team with support 
from the Computational Abilities Knowledge Exchange Network+. CAKE 
has received funding through the UKRI Digital Research Infrastructure
Programme under project reference UKRI1799.

Piper is a Research Software Engineer in Advanced Research Computing,
from the Rosalind Franklin Institute, piper.fowler-wright@rfi.ac.uk. 

Lewis also works as a Research Software Engineer , but for 
[DAFNI](https://dafni.ac.uk/) within STFC's Scientific computing
department.  lewis.sampson@stfc.ac.uk