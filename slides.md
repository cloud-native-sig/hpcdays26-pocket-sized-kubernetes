---
marp: true
theme: default
paginate: true
header:
  <img src='./mkdocs/docs/assets/CN-SIG-logo.png' width='200px' style='padding-left:1050px'></img>
---

<style>

section {
  background: white;
  color: black;
  padding-top: 110px;
  font-size: 29px;
}
section ul, section ol {
  font-size: 24px;
}
h1 {color: teal}

.centered-image {
    display: block;
    margin-left: auto;
    margin-right: auto;
}

</style>

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

# Introductions

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

### Note On *Docker Swarm*

Docker Engine's [Swarm mode](https://docs.docker.com/engine/swarm/) has many goals in common with Kubernetes, but is not as actively developed, feature-rich or has the same level of resilience for production use.

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

For more on this see, [our extra reading](./extra-reading.md) section on Kubernetes and HPC.

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

### How it works

Kubernetes follows a *declarative* approach where you define the target state of the applications running in the cluster, and Kubernetes works continuously to achieve that state. For example, if a node goes down, Kubernetes may distribute its workload to other nodes to ensure services for running applications are not interrupted.Kubernetes management follows the Infrastructure as Code paradigm and is readily integrated with GitOps using high-level tools such as [ArgoCD](https://argoproj.github.io/cd/).

---
---
---
---

# Using Kubernetes in your work

Everything you have learned today can be used in your own work. For further reading on the requirements to scale to production please see:

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
