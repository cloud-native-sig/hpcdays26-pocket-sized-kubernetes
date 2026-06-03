---
marp: true
theme: default
paginate: true
header:
  <img src='./mkdocs/docs/assets/CN-SIG-logo.png' width='200px' style='padding-left:1050px'></img>
  <img src='./slide-assets/k8s-cake-logo.png' width='100px' style="float:centre"></img>
style: |
  /* Define global background, subtle gradient, and layout framework */
  section {
    background: linear-gradient(135deg, #fdfbfb 0%, #e4f5f5 100%);
    color: #000000;
    padding: 50px;
    position: relative;
  }
  
  /* Create a left-side vertical accent border on every slide */
  section::before {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    width: 8px;
    height: 100%;
    background: linear-gradient(to bottom, #008080, #005555);
  }
  /* Style headings for crisp scannability */
  h1 {
    {color: #008080}
    font-weight: 700;
  }
  h2 {
    {color: #008080};
  }

  /* Title slide template - Invert colour */
  section.title-slide::before {
    content: none !important;
  }
  section.title-slide::header {
    content: none !important;
  }
  section.Title {
    background: linear-gradient(135deg, #008080 0%, #003d3d 100%) !important;
    color: #ffffff;
    font-size: 45px;
    h1 {color: #ffffff;}
  }

  section ul, section ol {
    font-size: 24px;
    }
  .centered-image {
      display: block;
      margin-left: auto;
      margin-right: auto;
    }  
  /* Footer typography */
  footer {
    font-size: 0.55em;
    color: #7f8c8d;
    font-weight: 600;
  }


---

# Pocket-Sized Kubernetes: Building and Deployment with Raspberry Pi Clusters

## A Cloud Native SIG and CAKE Workshop

*16 June 2026, RH007, Durham University*

<p><img src="./slide-assets/github-pages-qr.png" style="width:200;height:200;float:right" alt="github pages QR code"> <https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes></p>

---

# Housekeeping

## Agenda

1. Introductions
1. Kubernetes background and cluster design
1. Section 1 - Building your cluster
1. Lunch break
1. Section 2 - Using your cluster
1. Summary, Q&A, Follow-up opportunities

---

<!-- _class: Title -->
<!-- _header: "" -->
# Introductions

---

## Who We Are

This workshop is delivered by the **Cloud Native Special Interest Group** (SIG) with support from the **Computational Abilities Knowledge Exchange** (CAKE) partnership.

We're a new community of research software engineers and technical professionals exploring cloud-native technologies in research software and digital infrastructure.

You can find more about the SIG and how to get involved at [https://cloudnative-sig.ac.uk/](https://cloudnative-sig.ac.uk/).

**Lewis Sampson** (DAFNI), *<lewis.sampson@stfc.ac.uk>*
**Piper Fowler-Wright** (Rosalind Franklin Institute), *<Piper.Fowler-Wright@rfi.ac.uk>*

---

## Todays session

By the end of the tutorial, you will have:

- A basic understanding of Kubernetes architecture and how it can be used in research computing
- Built a multi-node K3s cluster on Raspberry Pi hardware
- Deployed basic applications and observer key Kubernetes features
- Gained practical skills transferable to HPC and cloud environments

### Following Along at Home

<small> All code and resources used in this tutorial are available on the [tutorial's GitHub repository](https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes). If you want to follow along at home or perhaps run your own workshop, you can start by reading our [extra reading section.](./extra-reading.md) </small>

---

# Introduction to Kubernetes

## What is Kubernetes

Kubernetes (k8s) is an open-source container orchestration platform that automates deployment, scaling, and management of containerised applications across groups of machines.

---

# Kubernetes vs Docker Compose

**Docker** runs applications from built images in sandboxed environments called containers. **Docker Compose** is a declarative tool that allows you to run groups of containers with networking and storage volumes on a single host.

**Kubernetes** goes beyond Docker Compose by providing an orchestration pipeline for multi-host, multi-container applications. k8s allows complex containerised applications to run across multiple hosts in a cluster with powerful automation and management features.

---

>Note On *Docker Swarm* - Docker Engine's [Swarm mode](https://docs.docker.com/engine/swarm/) has many goals in common with Kubernetes, but is not as actively developed, feature-rich or has the same level of resilience for production use.

---

# Using Kubernetes in Research Computing

Developing a Kubernetes cluster is a good approach when you need to manage multiple containerised services across different machines, and may benefit from:

- Automatic scaling of workloads based on demand
- Rolling updates with minimal downtime
- Self-healing resilient systems with high-availability
- Portability between on-prem and cloud infrastructure

---

# Using Kubernetes in Research Computing

On the other hand, Kubernetes introduces complexity and has a significant learning curve, and so may not be appropriate for:

- Simple container applications that can run on a single host (use
  Docker Compose)
- HPC batch job management (use SLURM)
- Services offered by a cloud provider or technology you are already
  invested in
- Large-scale parallel filesystems (use dedicated solutions, e.g.,
  Lustre)

>For more on this see, [our extra reading](./extra-reading.md) section on Kubernetes and HPC.

---

# Architecture Overview

<figure style="text-align: center;">
  <img src="./mkdocs/docs/assets/kubernetes-overview.png" style="height: 450px;" alt="The components of a Kubernetes Cluster">
  <figcaption><small>The components of a Kubernetes cluster. <a href="https://kubernetes.io">[Overview Components]</a></small></figcaption>
</figure>

---

# Key Components

- **Node**: A physical or virtual machine in the cluster
- **Pod**: The smallest deployable unit consisting of one more containers that share storage/network
- **Deployment**: Manages a set of identical pods (defines desired state)
- **Service**: Stable network endpoint to access pods
- **Control Plane**: The brain of the cluster, makes decisions based on the current cluster state.
- **Worker Nodes**: Run the containerised applications using a
    container runtime.

Other critical components include the Controller Manager and Scheduler
on the control node and `etcd`, a key-value store for cluster data.

---

# How Kubernetes works

Kubernetes follows a *declarative* approach where you define the target state of the applications running in the cluster, and Kubernetes works continuously to achieve that state.

For example, if a node goes down, Kubernetes may distribute its workload to other nodes to ensure services for running applications are not interrupted.

Kubernetes management follows the Infrastructure as Code paradigm and is readily integrated with GitOps using high-level tools such as [ArgoCD](https://argoproj.github.io/cd/).

> Further information on Kubernetes architecture can be found on our [Introduction to Kubernetes workshop materials](https://cloud-native-sig.github.io/stfcfeb26-intro-to-kubernetes/).

---

<!-- _class: Title -->
<!-- _header: "" -->
# Designing a cluster

---

# The Distribution Landscape

While Kubernetes itself is standardised, various distributions package it differently. The most popular distributions include:

- Vanilla Kubernetes ([kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)) by CNCF&mdash;industry standard, fully-featured Kubernetes implementation
- [RKE2](https://docs.rke2.io/)&mdash;Rancher Kubernetes Enginer 2, is Rancher's enterprise-ready next-generation Kubernetes distribution.
- [K3s by Rancher](https://k3s.io/)&mdash;Minimal resource usage and ease of installation for IoT and Edge Computing
- [MicroK8s by Canonical](https://canonical.com/microk8s)&mdash;Batteries included lightweight distribution designed for ease-of-use ('ZeroOps')
- [Minikube](https://minikube.sigs.k8s.io/docs/)&mdash;Single-node cluster designed for local development.

---

# K3s and Hardware Requirements

For our RPi Kubernetes clusters we chose K3s, which is specifically designed to have a minimal footprint. It requires a minimum of 2 cores/2G RAM for control nodes and 1 core/512M for worker nodes.

> In K3s, the node running the control-plane is referred to as the **Server**, and all other nodes are called **Agents**.

---

# Raspberry Pi hardware and OS

Each of our RPi clusters has a 4GB RAM control node, and 1GB or 4GB worker nodes. We installed RPi OS Lite, a lightweight (non-GUI) version of the official Debian-based Raspberry Pi operating system, on 16/32G SD cards. Check out the [GitRepository](https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes/tree/main/workshop-setup) for specific details.

Again, more details for RPi's, OS, and Infrastructure options can be found over at our [Extra reading](./extra-reading.md) page on Github.

---

<!-- _class: Title -->
<!-- _header: "" -->
# Exercise 1 — Connecting to Your Nodes

---

## Connecting to Your Nodes

Each table should have a note with:

- Raspberry Pi IP addresses
- SSH login credentials
- WiFi credentials for the workshop router

You will also need to connect your laptop to our Router - `TP-Link_AP_2A5A_01`

> <small> While connected to the workshop router, your laptop will lose internet access. You might want to have [kubectl](https://kubernetes.io/docs/tasks/tools/) installed locally before connecting to the router. </small>

---

## Verify SSH Access

Once you have connected to the router, as a group, you will need to confirm you can connect to each node:

```bash
ssh chef@192.168.x.xxx
hostname
exit
```

## Test Node Connectivity

From the control node, lets verify the worker nodes are reachable:

```bash
ssh chef@kmaster
ping -c3 192.168.x.yyy
```

---

## Troubleshooting

We should have configured static IPs through our router's DHCP settings.
But, if a node is unreachable we will need to:

1. Verify the IP address
1. Check the node is powered on
1. Confirm `sshd` is running
1. Configured a static IPs using `nmcli` or `nmtui`.

If needed, ask one of the course facilitators to help by connecting the Raspberry Pi to a display and keyboard for debugging

---

## Optional: configure Host Aliases

You may want to add IP-hostname pairs to `/etc/hosts/` on your device:

```text
192.168.x.xxx    kmaster
192.168.x.yyy    kworker1
```

<small>

You can then use `ssh <username>@kmaster`, instead of having to remember all the IP addresses.

Or configure SSH aliases in `~/.ssh/config`, then connect to the desired node with `ssh kworker01`

```text
Host kworker01
    HostName 192.168.x.yyy
    User chef
    IdentityFile ~/.ssh/id_ed25519
```

</small>

---

## Optional: Configure SSH Keys

To avoid repeatedly entering passwords you can setup SSH keys to make login more streamlined:

```bash
ssh-keygen -t ed25519
ssh-copy-id chef@kmaster
```

Repeat for each node if desired.

---

---

---

---

---

---

---

---

---

---

---

---

# Using Kubernetes in your work

Everything you will learn today can be used in your own work. For further reading on the requirements to scale to production please see:

<img src='slide-assets/qr.png' width=200px class=centered-image></img>
*<https://github.com/cloud-native-sig/stfcfeb26-intro-to-kubernetes/>*

---

# Knowledge Exchange opportunities

## Cloud Native SIG

This workshop was brought to you by the Cloud-Native SIG, with support from the **Software Sustainability Institute**

&nbsp;&nbsp;&nbsp;**Join us:**

- ✉️ <cloudnative-sig@jiscmail.ac.uk>
- 🌐 cloudnative-sig.ac.uk

<img src='slide-assets/SSI-LOGO.png' ></img>

---

# Knowledge exchange opportunities

## CAKE Fellowship

Read more here - <https://www.cake.ac.uk/ke-fellowships/cohort1>
<br>

## SCD Kubernetes colaboration group

Contact Lewis - <lewis.sampson@stfc.ac.uk> for more information.

---

# Thanks for your participation
