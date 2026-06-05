# Exercise 1a — Services and networking

This section will focus on creating an nginx deployment, looking at scaling pods, connecting services and testing cluster networks.

## Part 1 — NGINX deployment

We’ll begin by creating a  deployment running a single nginx pod:

```bash
kubectl create namespace nginx
kubectl apply -f $RES_HOME/nginx-deployment.yaml
```
Note `nginx-deployment.yaml` specifies a namespace called `nginx` for the deployment, which must be created
first. For this exercise, it will be convenient to set `kubectl` to target
this namespace: 
```bash
kubectl config set-context --current --namespace=nginx
```

You can now inspect the pod that started running with the deployment using
simply:
```bash
kubectl get pods -o wide
```

You should see a pod running with its own internal cluster IP (it may take a few seconds to be assigned). 
Even simple containers produce logs that can be inspected with `kubectl`:

```bash
kubectl logs deployment/nginx-demo
```

### Scaling the Deployment

One of Kubernetes’ core strengths is scaling workloads horizontally.

We can easily scale the deployment from 1 replica to 3:

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

## Part 2 — Creating a Cluster Service

Right now, the pods are completely isolated. To make them reachable from within the cluster virtual network, we create a Kubernetes Service.

```bash
kubectl apply -f $RES_HOME/nginx-service.yaml 
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

## Part 3 — Testing Connectivity Inside the Cluster

To debug networking inside Kubernetes, it is often useful to launch a temporary utility container.

We’ll use BusyBox:

```bash
kubectl apply -f $RES_HOME/busybox.yaml
```

This launches an interactive shell inside the cluster.

### DNS Resolution

Kubernetes automatically creates DNS records for Services using CoreDNS. Inside BusyBox, we can test Kubernetes DNS:

```bash
kubectl exec -it toolbox -- sh
/ nslookup nginx-service
```

Using CoreDNS, nslookup will resolve to the ClusterIP assigned to the Service, but you should see some warnings too. This is because we have not given the nslookup tool namespace information. Using `nslookup nginx-service.nginx.svc.cluster.local` will remove the warnings.

### Accessing the Service

Still inside BusyBox:

```bash
/ wget -qO- http://nginx-service
```

You should receive the default NGINX welcome page HTML.

The step by step process at this point is:

* BusyBox queried Kubernetes DNS,
* resolved the Service name,
* connected to the Service virtual IP,
* and Kubernetes forwarded traffic to one of the nginx pods.

All of this happened transparently.

### Observing Load Balancing

It is interesting to see the results if you run the request several times:

```bash
/ wget -qO- http://nginx-service
```

Although the webpage looks identical, Kubernetes may route each request to a different nginx pod behind the Service. The last line on the webpage output gives you the hostname.

To figure out which pod is related to which hostname, inspect the pod information:

```bash
kubectl get pods -o wide
```

## Part 4 — Exposing the Service Externally
So far our Service is only reachable from within the cluster.
To expose it on the router's network, the primitive approach is to setup a port forwarding rule for each node. 
This can be done editing `nginx-service.yaml`, changing `type: ClusterIP` to `type: NodePort` and adding a `nodePort` field:
```bash
ports:
- port: 80
  targetPort: 80
  nodePort: 30080
type: NodePort
```
You can now reach the service using any node's address:
```bash
curl kworker1:30080
```
Note that you must target a specific node&mdash;if that node goes down, the
endpoint becomes unreachable.  For a more robust solution, a dedicated Ingress
controller is created that sites in front of the nodes and provides a single
entry point.
 
## Summary

In this exercise you:

* deployed an application with Kubernetes,
* scaled it across multiple pods,
* exposed it using a Service,
* explored Kubernetes DNS,
* tested networking from inside the cluster using BusyBox, and outside via a
  `NodePort`

These ideas form the foundation for more advanced topics:

* ingress controllers,
* service meshes,
* observability,
* and multi-service applications.
