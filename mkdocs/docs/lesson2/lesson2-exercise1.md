# Exercise 1  Services and networking

This section will focus on creating an nginx deployment, looking at scaling pods, connecting services and testing cluster networks.

## Part 1 — NGINX deployment

We’ll begin by creating a Deployment running a single nginx pod.

```bash
kubectl create namespace nginx
kubectl apply -f resources/nginx-deployment.yaml
kubectl config set-context --current --namespace=nginx
```

and inspect the running pod:

```bash
kubectl get pods -o wide
```

You should see a pod running with its own internal cluster IP. Even simple containers produce logs that can be inspected with kubectl.

```bash
kubectl logs deployment/nginx-demo
```

### Scaling the Deployment

One of Kubernetes’ core strengths is scaling workloads horizontally.

Scale the deployment from 1 replica to 3:

```bash
kubectl scale deployment nginx-demo --replicas=3
```

Watch the new pods appear:

```bash
kubectl get pods -o wide -w
```

Notice:

* each pod has a unique IP address,
* pods may run on different nodes,
* all replicas are managed automatically by the Deployment.

If a pod fails, Kubernetes will attempt to replace it automatically.

## Exposing the Deployment

Right now the pods are isolated inside the cluster. To make them reachable, we create a Kubernetes Service.

```bash
kubectl apply -f resources/nginx-service.yaml 
kubectl get svc
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
kubectl get endpoints nginx-service
```

or:

```bash
kubectl describe service nginx-service
```

You should see the IP addresses of all nginx pods currently backing the Service.

## Testing Connectivity Inside the Cluster

To debug networking inside Kubernetes, it is often useful to launch a temporary utility container.

We’ll use BusyBox:

```bash
kubectl apply -f resources/busybox.yaml
```

This launches an interactive shell inside the cluster.

### DNS Resolution

Kubernetes automatically creates DNS records for Services using CoreDNS. Inside BusyBox, we can test Kubernetes DNS:

```bash
$ kubectl exec -it toolbox -- sh
/ # nslookup nginx-service
```

Using CoreDNS nslookup will resolve to the ClusterIP assigned to the Service, but you should see some warnings too. This is because we have not given the nslookup tool namespace information. Using `nslookup nginx-service.nginx.svc.cluster.local` will remove the warnings.

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

To figure out which pod is related to which hostname, inspect the pod information:

```bash
kubectl get pods -o wide
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
