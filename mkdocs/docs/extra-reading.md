## Using Your Own Hardware

All code and resources used in this tutorial are available
on the [tutorial's GitHub repository](https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes).
If you want to follow along at home or perhaps run your own workshop,
you can replicate our cluster setup with:

- 2-4 Raspberry Pi boards (Pi 3B+ or newer recommended&mdash;see
  [Hardware Requirements](designing-a-cluster.md#k3s-and-hardware-requirements))
- MicroSD cards (16GB+) & Power Supplies for each RPi
- at least one microHDMI-HDMI cable plus external display
- Network connectivity (WiFi or Ethernet/switches)
- A laptop or PC with SSH client

To prepare each RPi, we recommend using the [Raspberry Pi
Imager](https://www.raspberrypi.com/software/) to install RPi OS Lite
64-Bit for the device. The installer allows you to set the RPi
hostname, configure wireless connectivity, enable SSH and create an
initial login account.

On first boot, connect the device to an external monitor and log in to
check network connectivity and obtain the device IP address.  In order
to install K3s, you will need to enable memory cgroups by editing
`/boot/firmware/cmdline.txt` and appending to the end of the existing
line:

```
cgroup_memory=1 cgroup_enable=memory
```

After saving the file, reboot the RPi. You can now disconnect the
external monitor and connect via SSH from your own laptop or PC.

!!! note "Kubernetes Anywhere"
    While we used Raspberry Pis for the tutorial, K3s can be installed
    on a wide range of hardware from homelab servers to cloud server
    instances.

## Kubernetes and HPC

While we focus on learning Kubernetes through standard
application deployments, those interested in HPC integration
should explore the [**slinky**](https://slinky.schedmd.com/en/latest/)
project by SchemMD that enables interoperability between SLURM
and Kubernetes. This includes `slurm-operator` for
running SLURM on Kubernetes (as pods) and `slurm-bridge` for
using SLURM to schedule Kubernetes workloads.

## Raspberry Pi hardware and OS

Each of our RPi clusters has an RPi4 control node with a quad-core CPU
and 4G LPDDR4 RAM, and quad-core RPi4/5 worker nodes with 1G RAM.
We installed RPi OS Lite, a lightweight (non-GUI) version of
the official Debian-based Raspberry Pi operating system, on 16G SD
cards. You can purchase RPi hardware and accessories from UK retailers
[The PiHut](https://thepihut.com/),
[Rapid](https://www.rapidonline.com) and
[PIMORONI](https://shop.pimoroni.com/).

### Talos Linux and Immutable Infrastructure

For production clusters,
[Talos Linux](https://www.talos.dev/) is a modern Linux OS
designed specifically for running Kubernetes. It is an example of an
*immutable* operating system where the kernel runs from a read-only
filesystem and is API-driven, meaning all configuration occurs via
API calls.  This presents some learning curve and initial setup
challenges (there is no shell!), but is worth considering if you
want a highly reproducible and secure platform for Kubernetes
delivered as IaC.

### Cloud Provider Offerings

While we were keen to get you to install on bare metal in this
tutorial, Kubernetes is installed regularly on VPSes and in the Cloud.
Amazon, Google and Microsoft all provide *managed* Kuberentes
services where they handle the control-plane and patching. You lose
some control but may find this convenient if you are already invested
in their services. For more information, see [Amazon
EKS](https://aws.amazon.com/pm/eks-anywhere), the
[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine)
and the [Azure Kubernetes
Service](https://azure.microsoft.com/en-us/products/kubernetes-service/).

### Kubernetes metrics-server

`metrics-server` is a lightweight Kubernetes component that collects
resource usage information from nodes and pods.

It provides metrics such as:

- CPU usage
- Memory usage

These metrics are exposed through the Kubernetes Metrics API and are
used by commands such as:

```bash
kubectl top nodes
kubectl top pods
```

Unlike Prometheus, `metrics-server` is intentionally lightweight and
only keeps short-term resource metrics.

It is designed primarily for:

- quick cluster monitoring,
- autoscaling,
- and operational visibility.

The metrics pipeline looks roughly like this:

```text
Pod / Node
    ↓
Kubelet
    ↓
metrics-server
    ↓
Kubernetes Metrics API
    ↓
kubectl top
```

`metrics-server` periodically queries the kubelets on each node,
aggregates the data, and exposes it through the Kubernetes API.

This allows Kubernetes tooling to retrieve live cluster metrics in a
consistent way.

For larger production systems, Prometheus is more common because it
supports historical storage, alerting, dashboards, and custom metrics.

The official installation is usually done with:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

This deploys:

- the metrics-server Deployment,
- RBAC permissions,
- API services,
- and required Kubernetes resources.

Verifying the metrics-server deployment with:

```bash
kubectl get pods -A | grep metrics-server
kubectl describe deployment metrics-server -n kube-system

```

```bash
kubectl top nodes
```

and:

```bash
kubectl top pods
```

Or inspect logs:

```bash
kubectl logs -n kube-system deploy/metrics-server
```

This can be useful for troubleshooting connectivity or certificate
issues.
