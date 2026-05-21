# Exercise 3 — Persistent Storage

So far, most of the workloads we have deployed have been *ephemeral*.  
If a pod is deleted and recreated, any files written inside the container are typically lost.

In this exercise we will explore how Kubernetes manages persistent storage using:

- Persistent Volumes (PV)
- Persistent Volume Claims (PVC)
- Stateful workloads

We will:

- create persistent storage,
- attach it to a pod,
- verify data survives container recreation,
- and explore how Kubernetes separates compute from storage.

## Part 1 — Why Persistent Storage Matters

Containers are designed to be disposable.

This is extremely useful for scalability and recovery, but many real applications still need durable storage:

- databases,
- scientific outputs,
- checkpoints,
- shared datasets,
- logs,
- and user uploads.

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

It is lightweight and ideal for small clusters and workshops.

## Part 2 — Creating a Persistent Volume Claim

In Kubernetes, applications usually request storage through a Persistent Volume Claim (PVC).

The cluster then provides storage that satisfies the request.

Create:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim

metadata:
  name: demo-pvc

spec:
  accessModes:
    - ReadWriteOnce

  resources:
    requests:
      storage: 1Gi
```

Apply it:

```bash
kubectl apply -f pvc.yaml
```

---

### Inspecting the Claim

Check the PVC:

```bash
kubectl get pvc
```

You should see:

```text
NAME       STATUS   VOLUME                                     CAPACITY
demo-pvc   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   1Gi
```

The claim should automatically bind to a Persistent Volume provided by the cluster.

Since K3s includes the `local-path-provisioner` by default, storage is dynamically provisioned automatically.

---

### Inspecting the Persistent Volume

View the created PV:

```bash
kubectl get pv
```

Describe it:

```bash
kubectl describe pv <pv-name>
```

Notice:

- capacity,
- reclaim policy,
- storage class,
- and the claim reference.

---

## Part 3 — Using Persistent Storage in a Pod

Now we will mount the PVC into a container.

Create:

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: storage-demo

spec:
  containers:
    - name: writer

      image: bash

      command:
        - /bin/sh
        - -c
        - |
          while true; do
            date >> /data/output.txt
            sleep 5
          done

      volumeMounts:
        - name: demo-storage
          mountPath: /data

  volumes:
    - name: demo-storage
      persistentVolumeClaim:
        claimName: demo-pvc
```

Apply it:

```bash
kubectl apply -f storage-demo.yaml
```

---

### Observing the Data

Watch the file being written:

```bash
kubectl exec -it storage-demo -- sh
```

Inside the pod:

```bash
cat /data/output.txt
```

You should see timestamps continuously being appended.

Exit the shell when finished.

---

### Demonstrating Persistence

Now delete the pod:

```bash
kubectl delete pod storage-demo
```

Importantly:

- the pod is deleted,
- but the Persistent Volume still exists.

Recreate the pod:

```bash
kubectl apply -f storage-demo.yaml
```

Once running again:

```bash
kubectl exec -it storage-demo -- sh
```

Then inspect the file:

```bash
cat /data/output.txt
```

The previous data should still be present.

This is the key difference between:

- ephemeral container storage,
- and persistent Kubernetes volumes.

---

### Persistent Workloads with Deployments

Most real applications use Deployments or StatefulSets rather than standalone pods.

Create:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: persistent-nginx

spec:
  replicas: 1

  selector:
    matchLabels:
      app: persistent-nginx

  template:
    metadata:
      labels:
        app: persistent-nginx

    spec:
      containers:
        - name: nginx

          image: nginx

          volumeMounts:
            - name: web-storage
              mountPath: /usr/share/nginx/html

      volumes:
        - name: web-storage
          persistentVolumeClaim:
            claimName: demo-pvc
```

Apply it:

```bash
kubectl apply -f persistent-nginx.yaml
```

---

#### Writing Persistent Content

Exec into the pod:

```bash
kubectl exec -it deploy/persistent-nginx -- sh
```

Create a webpage:

```bash
echo "<h1>Hello Persistent Kubernetes</h1>" > /usr/share/nginx/html/index.html
```

Exit the shell.

---

#### Expose the Deployment

```bash
kubectl expose deployment persistent-nginx \
    --port=80 \
    --target-port=80 \
    --name=persistent-nginx
```

Test it:

```bash
kubectl run curl-test \
    --image=curl \
    -it --rm \
    --restart=Never -- \
    curl http://persistent-nginx
```

You should see:

```html
<h1>Hello Persistent Kubernetes</h1>
```

---

#### Demonstrating Persistence During Failure

Delete the nginx pod:

```bash
kubectl get pods
kubectl delete pod <pod-name>
```

Kubernetes will create a replacement pod automatically.

Once the new pod is running:

```bash
kubectl run curl-test \
    --image=curl \
    -it --rm \
    --restart=Never -- \
    curl http://persistent-nginx
```

The webpage should still exist.

Even though:

- the original container disappeared,
- the pod changed,
- and the workload restarted,

the persistent volume preserved the application data.

---

## Discussion — Why This Matters

Persistent storage is essential for many workloads, including:

- databases,
- scientific pipelines,
- model checkpoints,
- shared datasets,
- logs,
- and user uploads.

However, storage in Kubernetes introduces additional complexity:

- scheduling constraints,
- node locality,
- performance considerations,
- and failure recovery behaviour.

This becomes especially important in HPC and research computing environments.

---

### Optional Exploration

Inspect where the local-path storage exists on the node:

```bash
kubectl describe pv
```

You may notice paths similar to:

```text
/var/lib/rancher/k3s/storage/
```

On a real cluster this could instead map to:

- NFS,
- Ceph,
- Lustre,
- BeeGFS,
- or cloud block storage.

# Summary

In this exercise you:

- created Persistent Volume Claims,
- mounted persistent storage into pods,
- observed data surviving pod deletion,
- and explored how persistent workloads behave in Kubernetes.

You also saw another important Kubernetes principle:

> Containers are usually disposable, but storage often is not.

Persistent storage is one of the key building blocks required for running real applications on Kubernetes clusters.