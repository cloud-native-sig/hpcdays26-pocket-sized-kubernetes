# Lesson 2 - Using your cluster

In this lesson, you'll 

# Additional preparations
Before you connect to the router, in this next session the cluster will need access to our demonstration deployment manifests. If you are using your local computer and have kubectl access to the cluster, you only need to checkout the git branch locally. 

```bash
$ git clone https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes.git
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
$ sudo k3s ctr images import /root/workshop-images.tar
```
If the file is missing from the node, alert Lewis and he'll help get the files.  

# Exercise 1 - Services and networking 

This section will focus on creating an nginx deployment, looking at scaling pods, connecting services and testing cluster networks.

## NGINX deployment

We’ll begin by creating a Deployment running a single nginx pod.

```bash
$ kubectl create namespace nginx
$ kubectl apply -f resources/nginx-deployment.yaml
$ kubectl config set-context --current --namespace=nginx
```
and inspect the running pod:

```bash
$ kubectl get pods -o wide
```
You should see a pod running with its own internal cluster IP. Even simple containers produce logs that can be inspected with kubectl.

```bash 
$ kubectl logs deployment/nginx-demo
```
### Scaling the Deployment

One of Kubernetes’ core strengths is scaling workloads horizontally.

Scale the deployment from 1 replica to 3:
```bash
$ kubectl scale deployment nginx-demo --replicas=3
```

Watch the new pods appear:
```bash
$ kubectl get pods -o wide -w
```

Notice:
* each pod has a unique IP address,
* pods may run on different nodes,
* all replicas are managed automatically by the Deployment.

If a pod fails, Kubernetes will attempt to replace it automatically.

## Exposing the Deployment

Right now the pods are isolated inside the cluster. To make them reachable, we create a Kubernetes Service.
```bash
$ kubectl apply -f resources/nginx-service.yaml 
$ kubectl get svc
```
You should see something similar to:
```bash
NAME            TYPE        CLUSTER-IP      PORT(S)
nginx-service   ClusterIP   10.43.x.xxx    80/TCP
```
The Service provides:

* a stable virtual IP,
* internal DNS resolution,
* and load balancing across the nginx pods.

Importantly, the Service remains stable even if pods are recreated.

### Inspecting Service Endpoints

We can see which pods the Service is forwarding traffic to:
```bash
$ kubectl get endpoints nginx-service
```
or:
```bash
$ kubectl describe service nginx-service
```
You should see the IP addresses of all nginx pods currently backing the Service.

## Testing Connectivity Inside the Cluster

To debug networking inside Kubernetes, it is often useful to launch a temporary utility container.

We’ll use BusyBox:
```bash
$ kubectl apply -f resources/busybox.yaml
```
This launches an interactive shell inside the cluster.

### DNS Resolution

Kubernetes automatically creates DNS records for Services using CoreDNS.Inside BusyBox, we can test Kubernetes DNS:
```bash
$ kubectl exec -it toolbox -- sh
/ # nslookup nginx-service
```
Using CoreDNS nslookup will resolve to the ClusterIP assigned to the Service, but should see some warnings too. This is because we have not given the nslookup tool namespace information. Using `nslookup nginx-service.nginx.svc.cluster.local` will remove the warnings. 

### Accessing the Service

Still inside BusyBox:
```bash
/ # wget -qO- http://nginx-service
```
You should receive the default NGINX welcome page HTML.

At this point:

* BusyBox queried Kubernetes DNS,
* resolved the Service name,
* connected to the Service virtual IP,
* and Kubernetes forwarded traffic to one of the nginx pods.

All of this happened transparently.

## Observing Load Balancing

Run the request several times:
```bash
/ # wget -qO- http://nginx-service
```

Although the webpage looks identical, Kubernetes may route each request to a different nginx pod behind the Service. The last line on the webpage output gives you the hostname.

To make the connections, inspect the pod information:
```bash
$ kubectl get pods -o wide
```

## Summary
In this exercise you:
* deployed an application with Kubernetes,
* scaled it across multiple pods,
* exposed it using a Service,
* explored Kubernetes DNS,
* and tested networking from inside the cluster using BusyBox.

These ideas form the foundation for more advanced topics such as:
* ingress controllers,
* service meshes,
* observability,
* and multi-service applications.

# Exercise 2 - Resource management 
## OOM 
## CPU contention 
## Failure recovery 


# Exercise 3 - Persistent storage 
## PV/PVC
## Persistent workloads

# Exercise 4 - Monitoring and telemetry 
## Grafana and Prometheus

# Exercise 5 - Jobs and batch execution 
## Kubernetes Jobs and CronJobs
## A Very Effective “Capstone Demo”

Distributed Monte Carlo π Estimator
Use:
•	Kubernetes Job 
•	parallel workers 
•	shared output volume 
•	Grafana monitoring 

This demonstrates:
•	distributed compute 
•	orchestration 
•	scaling 
•	failure handling 
•	telemetry 
And HPC audiences immediately understand the pattern.


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