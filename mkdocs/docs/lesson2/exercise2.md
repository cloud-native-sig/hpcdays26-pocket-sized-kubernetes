# Exercise 2 — Resource Management and Failure Recovery

In this exercise we will explore how Kubernetes manages memory limits and CPU
contention, and handles failed containers with automated recovery.

Rather than just discussing resource requests and limits conceptually, we will
intentionally create workloads that misbehave and observe how Kubernetes
responds.

By the end of the exercise you should understand:

* the difference between requests and limits,
* what happens during an Out Of Memory (OOM) event,
* how CPU throttling behaves,
* and how Kubernetes self-heals failed workloads.

## Part 1 — Memory Limits and OOM Kills

Containers do not have unlimited access to system memory. Kubernetes can enforce memory limits using Linux cgroups.

If a container exceeds its memory limit, the kernel may terminate it with an OOM kill.

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

!!! Exercise
    `memory-demo.yaml` specifies a pod to execute a memory test using the `stress-ng` benchmarking tool. Can you run the same test using an interactive pod? (See the [`kubectl run` example](exercise1b.md/#part-3-launch-a-client-pod) from the previous exercise). Explain why the test succeeds in this case (HINT: read about **limits** below). 

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

This will bring up your local editor or VIM on the RPI. Change:

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

We next create multiple CPU-intensive workloads and observe the effects by
deploying a CPU stress test:
```bash
kubectl apply -f $RES_HOME/cpu-demo.yaml
```

Top-the-pods to follow CPU consumption:
```bash
kubectl top pods
```

You should notice that CPU usage is capped near the defined limit, with multiple
pods competing for that CPU time. Note that scheduling across the cluster's nodes is
not necessarily even.

You can also inspect node utilisation:  
```bash
kubectl top nodes
```

### Optional: Inspect from Inside the Container

You can inspect CPU metrics from *within* a pod:
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

The Deployment defines the desired state, e.g. `replicas: 4`, and Kubernetes
continuously compares this state against the actual cluster state.  If the
actual state has fewer pods, the Deployment controller requests another one to
restore the specified replica count.

This declarative approach, and the reconciliation loop that results,
 is one of the core features of Kubernetes.

### Optional: Simulating Node Failure

If multiple worker nodes are available, you can simulate node failure.

From the control node:
```bash
kubectl get nodes
```
Power off or disconnect one worker node&mdash;warn your group before
doing this!

```bash
ssh kworker03
sudo systemctl stop k3s-agent
```

Then observe:

```bash
kubectl get pods -o wide -w
```

Eventually Kubernetes will mark the node as `NotReady`, evict any workloads, and recreate pods on healthy nodes
as appropriate. 
This process may take several minutes.

## Clean-up

Due to the nature of the stress-tests, you should definitely clean-up their resources (also resetting your
`kubectl` namespace) 
```bash
kubectl delete -f $RES_HOME/cpu-demo.yaml -f $RES_HOME/memory-demo.yaml
kubectl config set-context --curent --namespace=default
```

## Summary

In this exercise you explored resource requests and limits in Kubernetes, and
associated OOM kills, CPU throttling and automated workload recovery.  The
latter all comes back to the declarative design principle of Kubernetes, which
acts continuously to reconcile the cluster toward a desired state.  It is this
reconciliation behaviour is what allows Kubernetes to recover automatically from
many common failures and so provide high availability services.
