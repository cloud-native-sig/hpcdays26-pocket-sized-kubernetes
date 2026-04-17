# Designing a Cluster

Before creating a Kubernetes cluster, you need to choose a
*distribution* of Kubernetes to deploy and infrastructure 
(hardware) to deploy it on. These decisions will affect the
performance, cost and scalability of your deployment. While your
choice will depend on your project's resource and goals, below
we provide some general guidance and alternative solutions as
we explain our approach for low-powered Raspberry Pi clusters.

## Kubernetes Distributions and Hardware

### The Distribution Landscape

While Kubernetes itself is standardised, various distributions
package it differently with trade-offs in features, resource
requirements, and ease of use. The most popular distributions include:

- Vanilla Kubernetes ([kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)) by CNCF&mdash;industry standard,
  fully-featured Kubernetes implementation
- [K3s by Rancher](https://k3s.io/)&mdash;Minimal resource
  usage and ease of installation for IoT and Edge Computing
- [MicroK8s by Canonical](https://canonical.com/microk8s)&mdash;Batteries included lightweight distribution designed for ease-of-use ('ZeroOps')
- [Minikube](https://minikube.sigs.k8s.io/docs/)&mdash;Single-node cluster designed for local development 
- [RKE2](https://docs.rke2.io/)&mdash;Rancher Kubernetes Enginer 2, is Rancher's enterprise-ready next-generation Kubernetes distribution.

### K3s and Hardware Requirements

For our RPi Kubernetes clusters we chose K3s, which is specifically
designed to have a minimal footprint suitable for single-board, edge
and IoT devices on x86 or ARM. It requires a minimum of 2 cores/2G RAM
for control nodes and 1 core/512M for worker nodes, and has binaries
that come in under 80M (<180M for air-gapped installs). 

!!! note "K3S Architecture"
    In K3s, the node running the control-plane and datastore 
    components is referred to as the **Server**, and all other
    (worker) nodes are called **Agents**. K3s supports an embedded
    or external datastore using the Kubernetes standard etcd, but
    also enterprise-grade SQL databases like PostgresSQL. You
    can read more on the
    [Architecture](https://docs.k3s.io/architecture#) and [Cluster
    Datastore](https://docs.k3s.io/datastore) pages of the k3s
    documentation.
    
K3s is not limited to small, developmental servers. High-availability
K3s servers with over 500 nodes can be run on devices with as little
as 32vCPUs and 64G RAM. If you are interested in the upper limit for
standard Kubernetes, [Kubernetes v1.35](https://kubernetes.io/docs/setup/best-practices/cluster-large/) 
 supports clusters with up to 5,000 nodes running 150,000 total pods (300,000 
containers).

### Raspberry Pi hardware and OS
Each of our RPi clusters has an 4GB RAM control node, and 1GB worker nodes.
We installed RPi OS Lite, a lightweight (non-GUI) version of
the official Debian-based Raspberry Pi operating system, on 16G SD
cards.

!!! Warning Disk Requirements
    Kuberentes' `etcd` datastore is write-intensive and for optimal
    speed it is recommended to use SSD disks. SD Cards (or eMMc) cannot
    handle the IO load well and are the weakest link of our RPi clusters.

Again, more details for RPi's, OS, and Infrastructure options can be found
over at our [Extra reading](./extra-reading.md) page.