# Exercise 3 — Kubectl Basics

We have already seen that `kubectl` is the command-line interface for Kubernetes. Now we will explore the basics of how the tool can be used;

The general syntax is:

```bash
kubectl <command> <type> [name] [flags]
```

where `<command>` specifies the action to perform, `<type>` is the
type of Kubernetes *resource* (e.g., nodes, pods, deployments),
`[name]` is the optional name of the resource, and `[flags]` are
optional parameters.

Examples:

```bash
kubectl get nodes
kubectl describe node kworker01
```

## Access the Cluster From Your Laptop

Before we start using kubectl, you might prefer to connect to the cluster from you local computer (if not, feel free to skip this step). This is also required for running kubectl from other nodes.

To do this we need to copy the k3s.yaml file to our chosen environment.

To start with, whoever is on the contrl-plane node, move the file to the chef's home directory and give it the appropriate owner.

```bash
cp /etc/rancher/k3s/k3s.yaml /home/chef/
chown chef:chef /home/chef/k3s.yaml
```

Then from your local environment, or the worker nodes, copy the Kubernetes configuration file.

```bash
mkdir -p ~/.kube/
scp chef@kmaster:/home/chef/k3s.yaml ~/.kube/config-k3s
```

Edit the server to point to your control plane IP and api-server with `vi ~/.kube/config-k3s`:

```yaml
server: https://<control-node-ip>:6443
```

After exporting the config to the local environment:

```bash
export KUBECONFIG=~/.kube/config-k3s
```

You can now run all kubectl commands from your computer:

```bash
kubectl get nodes
```

For additional security you should typically limit access to this new file:

```bash
chmod 600 ~/.kube/config-k3s
```

## Kubernetes Namespaces

Namespaces are are often use to create logical separation of resources within a cluster. This allows you to have multiple applications or different deployments of an application such as `dev` and `prod`.

List all namespaces:

```bash
kubectl get namespaces
```

There are a number of pods running essential *system* processes in the `kube-system` namespace:

```bash
kubectl get pods --all-namespaces
```

Can you can match these to services from the Kubernetes [Introduction](../introduction.md#architecture-overview)?

## Exploring Cluster Resources

By default, `kubectl` refers to the `default` namespace. Since we have not deployed any applications in this namespace, `kubectl get deployments` and `kubectl get pods` will not return anything.

Switch to the `kube-system` namespace:

```bash
kubectl config set-context --current --namespace=kube-system
```

View *all* resources:

```bash
kubectl get all
```

This includes:

* Pods
* Deployments
* ReplicaSets
* Services
* Jobs

> `kubectl get all` does not quite show all the resources, but it does highlight the main ones.

---

### Resource Requests and Limits

Still using `kubectl` we can investigate exactly how and what is running on the cluster at this point.

### Inspecting Pods

We can start by inspecting the pods we have found in the `kube-system` namespace. Try this now with any of the following

#### Describe any pod

```bash
kubectl describe pod <pod-name>
```

#### Inspect a pod manifest output in YAML

```bash
kubectl get pod <pod-name> -o yaml
```

#### Inspect pod resources

To view the resources that are being used by these pods we can inspect the pod itself.

```bash
kubectl get pod -o json -l k8s-app=kube-dns | jq -r '.items[0].status.containerStatuses[].allocatedResources'
kubectl get pod -o json -l k8s-app=kube-dns | jq -r '.items[0].status.containerStatuses[].resources.limits'
```

> Our RPi's have not had jq installed. Instead try `kubectl get pod  -l k8s-app=kube-dns --output=jsonpath="{.items[0].status.containerStatuses[].allocatedResources}"`

#### Edit deployment resources via kubectl

```bash
kubectl edit deployment coredns
```

#### Patch directly via a single command

```bash
kubectl patch deployment coredns  -p '{"spec":{"template":{"spec":{"containers":[{"name":"coredns","resources":{"requests":{"cpu":"120m"}}}]}}}}'
```

### Storage and ConfigMaps

Pods are ephemeral, so persistent data is typically stored using:

* Persistent Volumes (PV)
* Persistent Volume Claims (PVC)
* ConfigMaps

We will have an in-depth session on this later, but lets take a quick look at those now. Inspect the CoreDNS configuration:

```bash
kubectl get cm coredns -o yaml
```

Check the pod manifest for volumes and volumemounts:

```bash
kubectl get pod -l k8s-app=kube-dns -o yaml | grep -i volumes -A 32
```

The above grabs a specific part of the yaml definition for the DNS pods, but feel free to inspect further by removing the pipe to `grep` command.

You should see something like the following.

```yaml
    - configMap:
        defaultMode: 420
        items:
        - key: Corefile
          path: Corefile
        - key: NodeHosts
          path: NodeHosts
        name: coredns
      name: config-volume
```

We can see that the DNS pod use the existing configmap to read in specifications for running the pod itself.

---

### Accessing Containers

For some pods, their containers allow interactive access:

```bash
kubectl exec -it <pod-name> -- sh
```

Example:

```bash
kubectl exec -it local-path-provisioner-<hash> -- sh
```

From here you can view the mounted volumes. See if you can find this where the configmap has been mounted, and where the data came from.
