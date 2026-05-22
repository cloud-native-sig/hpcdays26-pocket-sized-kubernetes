# Exercise 3 — Persistent Storage

At the end of the first Lesson, we discussed how most workloads deployed are *ephemeral*. If a pod is deleted and recreated, any files written inside the container are typically lost.

In this exercise we will explore how Kubernetes manages persistent storage using:

- Persistent Volumes (PV)
- Persistent Volume Claims (PVC)
- Stateful workloads

We will:

- Create persistent storage,
- Attach it to a pod,
- Verify data survives container recreation,
- Explore how Kubernetes separates compute from storage.

## Part 1 — Why Persistent Storage Matters

In all contexts containers are designed to be disposable. This is extremely useful for scalability and recovery, but many real applications still need durable storage. This storage can be used for:

- shared datasets and databases,
- user uploads and scientific outputs,
- workflow checkpoints,
- logging and debugging.

Kubernetes handles this by abstracting storage into separate resources.

### Kubernetes Storage Concepts

#### Persistent Volume (PV)

A Persistent Volume represents storage available to the cluster.

Examples include:

- local disks,
- network filesystems,
- cloud block storage,
- or parallel filesystems.

#### Persistent Volume Claim (PVC)

A Persistent Volume Claim is a request for storage made by a workload.

Pods generally consume PVCs rather than interacting with PVs directly.

This separation allows storage to be managed independently from applications.

### Inspecting the Local Path Provisioner

K3s includes a simple storage provisioner called:

```text
local-path-provisioner
```

Inspect the storage classes available:

```bash
kubectl get storageclass
```

You should see something similar to:

```text
local-path (default)
```

This provisioner dynamically creates storage directories on cluster nodes.

It is lightweight and ideal for small clusters and workshops. For production clusters, you can use CSI-backed file storage, NFS file storage or vendor distributed storage.  

## Part 2 — Creating a Persistent Volume Claim

In Kubernetes, applications usually request storage through a Persistent Volume Claim (PVC).

The cluster then provides storage that satisfies the request.

!!! tip  
    Before we start, move to the `resource-demo` namespace.

    `kubectl config set-context --current --namespace=resource-demo`

We have written a yaml manifest for our demo:

```bash
kubectl apply -f $RES_HOME/pvc.yaml
```

### Inspecting the Claim

Check the PVC:

```bash
kubectl get pvc
```

You should see:

```text
NAME       STATUS   VOLUME                                     CAPACITY
demo-pvc   Pending    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   
```

Since K3s includes the `local-path-provisioner` by default, storage is dynamically provisioned automatically.

The claim will not automatically bind since its the `local-path-provisioner` is set to `WaitForFirstConsumer` binding mode. This means that a Persistent Volume is provided when the cluster requests the resource.  

## Part 3 — Using Persistent Storage in a Pod

Now we will mount the PVC into a container.

```bash
kubectl apply -f $RES_HOME/storage-pod.yaml
```

### Inspecting the Persistent Volume

View the created PV:

```bash
kubectl get pv
```

Describe it:

```bash
kubectl describe pv <pv-name>
```

Here you can see the capacity, reclaim policy, storage class, and the claim reference.

### Observing the Data

Lets have a look at the file being written:

```bash
kubectl exec -it storage-pod -- sh
```

Inside the pod:

```bash
cat /data/output.txt
```

You should see timestamps continuously being appended. You can exit the shell when you're finished.

### Demonstrating Persistence

Now delete the pod:

```bash
kubectl delete pod storage-pod
```

This might not happen immediately. Sometimes pods take a while to be safely deleted. Importantly:

- Wait for the pod to be deleted,
- Check that the Persistent Volume and PVC still exists.

Now we can recreate the pod:

```bash
kubectl apply -f storage-pod.yaml
```

Once running again, inspect the file:

```bash
kubectl exec -it $RES_HOME/storage-pod -- sh
cat /data/output.txt
```

The previous data should still be present and you'll notice a gap in the timestamps from where the pod was not running.

This is demonstrates the key difference between ephemeral container storage and the persistent Kubernetes volumes.

### Persistent Workloads with Deployments

Most real applications use Deployments or StatefulSets rather than standalone pods.

For this demonstration we are going to recreate our NGINX deployment but with a volume mount.

```bash
kubectl apply -f $RES_HOME/nginx-deployment-persist.yaml
```

At this point we need to consider namespaces. PVC's are not accessible across namespaces, so we have created a new PVC in the NGINX namespace. From the single manifest.

Noting that the orginal PVC is RWO, multiple pods could not bind to the same volume. So the new nginx pvc will allow all the replicas to access the data.

#### Writing Persistent Content

Lets explore writting to this volume. Exec into a nginx pod:

```bash
kubectl exec -it deploy/nginx-demo -n nginx -- sh
```

Create a webpage:

```bash
echo "<h1>Hello Persistent Kubernetes</h1>" > /usr/share/nginx/html/persist.html
```

Exit the shell.

---

#### Optional: Expose the Deployment

Another method for creating a service in the expose command. Here we are creating a new service for our nginx deployment. You can still use the existing service.

```bash
kubectl expose deployment -n nginx nginx-demo \
    --port=80 \
    --target-port=80 \
    --name=persistent-nginx
```

Test it:

```bash
kubectl run curl-test \
    --image=workshop-tools:arm64 \
    -it --rm \
    --restart=Never -- \
    curl http://persistent-nginx.nginx.svc.cluster.local/persist.html
```

You should see:

```html
<h1>Hello Persistent Kubernetes</h1>
```

#### Demonstrating Persistence During Failure

Delete the nginx pod:

```bash
kubectl get pods -n nginx
kubectl delete pod -n nginx <pod-name>
```

Kubernetes will create a replacement pod automatically.

Once the new pod is running:

```bash
kubectl run curl-test \
    --image=workshop-tools:arm64 \
    -it --rm \
    --restart=Never -- \
    curl http://persistent-nginx.nginx.svc.cluster.local/persist.html
```

The webpage should still exist.

Even though the original container disappeared, the pod changed, and the workload restarted. The persistent volume preserved the application data.

## Summary

In this exercise you:

- created Persistent Volume Claims,
- mounted persistent storage into pods,
- observed data surviving pod deletion,
- and explored how persistent workloads behave in Kubernetes.

You also saw another important Kubernetes principle:

> Containers are usually disposable, but storage often is not.

Persistent storage is one of the key building blocks required for running real applications on Kubernetes clusters.

As mentioned earlier, persistent storage is essential for many workloads, including:

- shared datasets and databases,
- user uploads and scientific outputs,
- workflow checkpoints,
- logging and debugging.

However, storage in Kubernetes introduces additional complexity:

- scheduling constraints,
- node locality,
- performance considerations,
- and failure recovery behaviour.

### Optional Exploration

Inspect where the local-path storage exists on the node:

```bash
kubectl describe pv
```

You can ssh into the node and inspect this path. You'll also notice paths similar to it in:

```text
/var/lib/rancher/k3s/storage/
```

On a production environment, this could instead map to:

- NFS,
- Ceph,
- Lustre,
- BeeGFS,
- or cloud block storage.
