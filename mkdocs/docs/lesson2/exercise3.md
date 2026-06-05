# Exercise 3 — Persistent Storage

At the end of the first Lesson, we discussed how most workloads deployed are *ephemeral*. If a pod is deleted and recreated, any files written inside the container are typically lost.

In this exercise we will explore how persistence storage is managed in Kubernetes through Persistent Volumes (PV)
and Persistent Volume Claims (PVC), enabling stateful workloads.

We will:
- Create persistent storage
- Attach it to a pod
- Verify data survives container recreation

## Part 1 — Why Persistent Storage Matters

In all contexts containers are designed to be disposable. This is extremely useful for scalability and recovery, but many real applications still need durable storage. This storage could be used for shared datasets, databases, scientific outputs, logging, etc.

Kubernetes handles this by abstracting storage into separate resources.

### Kubernetes Storage Concepts

#### Persistent Volume (PV)

A Persistent Volume represents storage available to the cluster.

Examples of the type of storage backing a PV include local disks, network filesystems,
cloud block storage and parallel filesystems.

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

This provisioner dynamically creates storage directories on cluster nodes using
the local filesystem.

!!! tip
    *Local Path* is lightweight and ideal for small clusters and workshops. For production clusters, you can use CSI-backed file storage, NFS file storage or cloud vendor storage.  

## Part 2 — Creating a Persistent Volume Claim

In Kubernetes, applications usually request storage through a Persistent Volume Claim (PVC).

The cluster then provides storage that satisfies the request.

Our demo deployment wants a `storage-demo` namespace, so we need to make sure
it has been created (the command will fail harmlessly if it already exists):
```bash
kubectl create namespace storage-demo
kubectl config set-context --current --namespace=storage-demo
```

The yaml specification for the PVC is `pvc.yaml`. Apply this now:

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

Now we will mount the PVC into a container using the `storage-pod.yaml` Pod
specification:

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

## Persistent Workloads with Deployments

> This part extends from the deployment in [Exercise 1a](./exercise1a.md),
> but can be performed independently.

Most real applications use Deployments or StatefulSets rather than standalone pods.

For this demonstration we are going to recreate our NGINX deployment but with a volume mount.

```bash
kubectl apply -f $RES_HOME/nginx-deployment-persist.yaml
```

!!! warning
    To avoid conflict with anyone going through Exercise 1a, make sure you remain in the `storage-demo` namespace for this deployment.

The deployment defines a new PVC in the namespace, `nginx-pvc`. Note while our
first PVC had an `accessMode` of
`ReadWriteOnce` or *RWO*, meaning 
the volume can be mounted a read-write by a single *node*, the new one has 
`ReadWriteMany` (RWM), which is critical to allow replicas spawned on different
nodes to have access to the storage.

!!! info
    You can read about the different possible *Access Modes* (RWO, ROX, RWX and RWOP) for PVCs on the Kubernetes Documentation on [persistent-volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes).

### Writing Persistent Content

Lets explore writing to this volume. Execute into a nginx pod:

```bash
kubectl exec -it deploy/nginx-demo -n nginx -- sh
```

Create a webpage:

```bash
echo "<h1>Hello Persistent Kubernetes</h1>" > /usr/share/nginx/html/persist.html
```

Exit the shell.

---

### Optional: Expose the Deployment to the Cluster

In Exercise 1a we declared a service with type `ClusterIP` via a `.yaml` file to allow access to
the NGINX server from within the cluster. Another way to achieve this is
using the expose command:
```bash
kubectl expose deployment nginx-demo \
    --port=8081 \
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

### Demonstrating Persistence During Failure

Delete the nginx pod:
```bash
kubectl delete pods -n storage-demo -l app=nginx-demo
```
Kubernetes will create a replacement pods automatically.

!!! tip
    `-l app=nginx-demo` is an example of matching using a *label selector*. Labels and selectors and an immensely useful way to make targeted changes to deployments and other resources in Kubernetes.  

Once a new `nginx-demo` pod is running:

```bash
kubectl run curl-test \
    --image=workshop-tools:arm64 \
    -it --rm \
    --restart=Never -- \
    curl http://persistent-nginx.nginx.svc.cluster.local/persist.html
```
The webpage should still exist.
Even though the original container disappeared, the pod changed, and the workload restarted. The persistent volume preserved the application data.

## Clean-up
Remove any of the resources you used in this session, including the service
created by the expose command (if you ran it):
```
kubectl delete -f $RES_HOME/pvc.yaml -f $RES_HOME/storage-pod.yaml -f $RES_HOME/nginx-deployment-persist.yaml
kubectl detele service nginx-demo
```
You can then reset your configured `kubectl` namespace:
```
kubectl config set-context --curent --namespace=default
```

## Summary

Persistent storage is one of the key building blocks required for running real applications on Kubernetes clusters.

In this exercise you saw how persistent workloads are possible 
using Persistent Volume Claims mounted into pods that survive pod recreation or
deletion. Note the general principle in Kubernetes: 

> Containers are usually disposable, but storage often is not.

While essential for many workloads, persistent storage does introduce additional complexity
to your cluster, often bringing
scheduling constraints, node locality, and considerations regarding performance and failure recovery behaviour.

## Optional: Node Storage Paths

Inspect where the local-path storage exists on the node:

```bash
kubectl describe pv
```

You can ssh into the node and inspect this path. You'll also notice paths similar to it in:

```text
/var/lib/rancher/k3s/storage/
```

On a production environment, this could instead map to NFS, Ceph, Lustre, BeeGFS
etc.
