# Exercise 2 — Resource Management and Failure Recovery

In this exercise we will explore how Kubernetes manages:

* memory limits,
* CPU contention,
* failed containers,
* and automatic recovery.

Rather than just discussing resource requests and limits conceptually, we will intentionally create workloads that misbehave and observe how Kubernetes responds.

By the end of the exercise you should understand:

* the difference between requests and limits,
* what happens during an Out Of Memory (OOM) event,
* how CPU throttling behaves,
* and how Kubernetes self-heals failed workloads.

## Part 1 — Memory Limits and OOM Kills

Containers do not have unlimited access to system memory. Kubernetes can enforce memory limits using Linux cgroups.

If a container exceeds its memory limit, the kernel may terminate it with an OOM (Out Of Memory) kill.

We will intentionally trigger this behaviour by deploying a Memory Stress Test

First we will create and move to a new namespace.

```bash
kubectl create namespace resource-demo
kubectl config set-context --current --namespace=resource-demo
```

Using the memory-demo.yaml manifest, apply a new deployment:

```bash
kubectl apply -f $RES_HOME/memory-demo.yaml
```

### Observing the Failure

Watch the pod status:

```bash
kubectl get pods -w
```

After a short time the pod should enter `OOMKilled` or `CrashLoopBackOff`. Kubernetes will continually attempt to restart the container.

### Inspect the Pod

Describe the pod:

```bash
kubectl describe pod -l app=memory-demo
```

Look for:

```bash
Reason: OOMKilled
```

This indicates the Linux kernel terminated the process because it exceeded its memory limit.

### Understanding Requests vs Limits

The deployment specified both:

```bash
requests:
  memory: "64Mi"

limits:
  memory: "128Mi"
```

**Requests** - Requests are used by the Kubernetes scheduler. They represent the minimum resources Kubernetes should reserve for the pod.

**Limits** - Limits are enforced at runtime. If the container exceeds its limit, Kubernetes may throttle it (CPU) or terminate it (memory).

### Fixing the Memory Issue

Increase the memory limit:

```bash
kubectl edit deployment memory-demo
```

This will bring up your local editer or VIM on the RPI. Change:

```bash
limits:
  memory: "128Mi"
```

to:

```bash
limits:
  memory: "512Mi"
```

Save and exit.

Kubernetes will automatically create a replacement pod using the updated configuration. Now we verify the new pod remains running:

```bash
kubectl get pods
```

## Part 2 — CPU Contention and Throttling

Unlike memory limits, CPU limits do not usually terminate containers. Instead, the Linux scheduler throttles CPU usage.

We will create multiple CPU-intensive workloads and observe the effects.

Deploying a CPU Stress Test:

```bash
kubectl apply -f $RES_HOME/cpu-demo.yaml
```

### Watching CPU Usage

Now the pods have been deployed we can observe the CPU consumption:

```bash
kubectl top pods
```

You should notice:

* CPU usage capped near the defined limit,
* multiple pods competing for CPU time,
* and potentially uneven scheduling across nodes.

You can also inspect node utilisation:  

```bash
kubectl top nodes
```

### Optional: Inspect from Inside the Container

You can inspect CPU visibility directly inside a pod:

```bash
kubectl exec -it deploy/cpu-demo -- sh
```

Then run `nproc`, `top`, or `htop`

## Part 3 — Failure Recovery

One of Kubernetes’ most important features is automatic recovery from failure.

We will intentionally terminate a container process and observe Kubernetes replacing it.

### Delete a Pod

List pods:

```bash
kubectl get pods
```

Delete one:

```bash
kubectl delete pod <pod-name>
```

Immediately watch the Deployment recover:

```bash
kubectl get pods -w
```

A replacement pod should appear automatically.

### Why Did the Pod Return?

The pod itself is not the important object.

The Deployment defines the desired state, e.g. `replicas: 4`

Kubernetes continuously compares the desired state, against actual cluster state.

When a pod disappears, the Deployment controller creates another one to restore the requested replica count.

This reconciliation loop is one of the core ideas behind Kubernetes.

### Optional: Simulating Node Failure

If multiple worker nodes are available, you can simulate node failure.

From the control node:

kubectl get nodes

Power off or disconnect one worker node.

```bash
ssh kworker03
sudo systemctl stop k3s-agent
```

Then observe:

```bash
kubectl get pods -o wide -w
```

Eventually Kubernetes will:

* mark the node NotReady,
* evict workloads,
* and recreate pods on healthy nodes.

This process may take several minutes.

## Summary

In this exercise you explored:

* resource requests and limits,
* Out Of Memory (OOM) kills,
* CPU throttling,
* Kubernetes scheduling,
* and automatic workload recovery.

You also saw an important Kubernetes design principle in practice:

Kubernetes is continuously attempting to reconcile the cluster toward a desired state. This reconciliation behaviour is what allows Kubernetes to recover automatically from many common failures.