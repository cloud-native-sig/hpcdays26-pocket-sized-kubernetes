# Lesson 2 — Using your cluster

In this lesson, you'll

# Exercise 3 - Persistent storage

## PV/PVC

## Persistent workloads

# Exercise 4 - Monitoring and telemetry

## Grafana and Prometheus

## iperf3

# Exercise 5 - Jobs and batch execution

## Kubernetes Jobs and CronJobs

## A Very Effective “Capstone Demo”

# Exercise 3 - Persistent storage

## PV/PVC

## Persistent workloads

# Exercise 4 - Monitoring and telemetry

## Grafana and Prometheus

## iperf3

# Exercise 5 - Jobs and batch execution

## Kubernetes Jobs and CronJobs

## A Very Effective “Capstone Demo”

Distributed Monte Carlo π Estimator
Use:
• Kubernetes Job
• parallel workers
• shared output volume
• Grafana monitoring

This demonstrates:
• distributed compute
• orchestration
• scaling
• failure handling
• telemetry
And HPC audiences immediately understand the pattern.

## Some additional setup steps preparations

Before you connect to the router, in this next session the cluster will need access to our demonstration deployment manifests. If you are using your local computer and have kubectl access to the cluster, you only need to checkout the git branch locally.

```bash
git clone https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes.git
```

If you are accessing the nodes via ssh and using kubectl from here, copy at least the resources repository to the node youre using.

```bash
$ scp -r resources/ chef@kmaster:~/
$ ssh chef@kmaster
$ ls -l 
total 12 \n
drwxr-xr-x 2 chef chef 4096 May 13 04:57 resources
-rwxrwxr-x 1 chef chef 4880 May 10 02:04 setup-rpi-worker.sh
```

Only one person per group will *need* to deploy manifetes, but it may be useful for everyone to have visibility of the code, and to share hands-on practice. We will use `RES_HOME` throughout the for where your resource folder is stored.

Also since the cluster is air-gapped we need install images differently. For these clusters, you'll use a set of pre-loaded images since the pods wont be able to access them directly from Docker Hub itself.

Each node should have a file present at  /root/workshop-images.tar and you can load it onto that nodes memory using

```bash
sudo k3s ctr images import /root/workshop-images.tar
```

If the file is missing from the node, alert Lewis and he'll help get the files.  

## Acknowledgements

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
