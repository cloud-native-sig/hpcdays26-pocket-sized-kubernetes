# Lesson 2: Deploying to the cluster

In this lesson, you'll 
## Connecting to Your Nodes
Lets start by ensuring you can connect to all the nodes in your cluster

```
export KUBECONFIG=~/.kube/config-k3s
kubectl get nodes 
ssh chef@kmaster # If you're using updates to /etc/hosts for kmaster
kubectl get nodes
```

## Installing K3s images 

As well as some other packages, we have prepared the cluster to contain images that we will use throughout 
this workshop. In you own setup you may not need to do this, due to being able to pull imags from docker
registry in the normal steps.

To load the images so they are available, on each node, run the following;

```
sudo k3s ctr images import /root/workshop-images.tar
sudo k3s ctr images ls | grep -iE 'nginx|busybox|perl|stress'
```

### Retrieve the Join Token


### Worker Nodes (Agents)

#### With internet

#### Without internet
### Verify the Cluster

