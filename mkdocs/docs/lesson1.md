# Lesson 1: Designing Your Cluster

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

### K3s and Hardware Requirements

For our RPi Kubernetes clusters we chose K3s, which is specifically
designed to have a minimal footprint suitable for single-board, edge
and IoT devices on x86 or ARM. It requires a minimum of 2 cores/2G RAM
for control nodes and 1 core/512M for worker nodes, and has binaries
that come in under 80M (<180M for air-gapped installs). While you
*might* be able to install vanilla Kubernetes on 2 core/2G nodes, it
is unlikely to provide stable yet alone performant deployments.
MicroK8s, for example, itself a fairly lightweight distribution,
recommends at least 4G of memory and 20G disk space.

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
standard Kubernetes, Kubernetes v1.35 [supports clusters with up to
5,000 nodes running 150,000 total pods (300,000
containers).](https://kubernetes.io/docs/setup/best-practices/cluster-large/) 

### Raspberry Pi hardware and OS
Each of our RPi clusters has an RPi4 control node with a quad-core CPU
and 4G LPDDR4 RAM, and quad-core RPi4/5 worker nodes with 1G RAM.
We installed RPi OS Lite, a lightweight (non-GUI) version of
the official Debian-based Raspberry Pi operating system, on 16G SD
cards. You can purchase RPi hardware and accessories from UK retailers
[The PiHut](https://thepihut.com/),
[Rapid](https://www.rapidonline.com) and
[PIMORONI](https://shop.pimoroni.com/).

!!! Warning Disk Requirements
    Kuberentes' `etcd` datastore is write-intensive and for optimal
    speed it is recommended to use SSD disks. SD Cards (or eMMc) cannot
    handle the IO load well and are the weakest link of our RPi clusters.


## Talos Linux and Immutable Infrastructure

For production clusters, 
[Talos Linux](https://www.talos.dev/) is a modern Linux OS
designed specifically for running Kubernetes. It is an example of an
*immutable* operating system where the kernel runs from a read-only
filesystem and is API-driven, meaning all configuration occurs via
API calls.  This presents some learning curve and initial setup
challenges (there is no shell!), but is worth considering if you
want a highly reproducible and secure platform for Kubernetes
delivered as IaC.

## Cloud Provider Offerings

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
