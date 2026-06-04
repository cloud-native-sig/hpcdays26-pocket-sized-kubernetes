# Lesson 2 — Using your cluster

In this lesson, you'll begin to deploy a range of resources onto the cluster. As we are working with an air-gapped installation, there are limitations to what we can deploy. Regardless, we will still be able to cover important topics including:

* Services, networking and Monitoring
* Resource Management and Failure Recovery
* Persistent Storage
* Jobs and Batch Execution

Through this session you will see first-hand the benefits of using Kubernetes to manage high availability application deployments and how this relates to HPC environments. 

## Namespaces
For the exercises in this section we will make use of Kubernetes *namespaces*
which provide a way of organising resources associated with different
deployments. A namespace can be created using `kubectl` with
```bash
kubectl create namespace my-app
```
You can then target resources in these namespace by appending `-n my-app` to any
`kubectl` call. For example, to get pods running `my-app`:
```bash
kubectl get pods -n my-app
```
Without creating specific namespaces, every deployment your group makes will
land in the `default` namespace, leading to quite a mess. 

!!! Warning
    If you choose to work asynchronously on different exercises within your group, make sure to communicate to each other which namespaces and deployments you create.

For convenience, whilst working on a specific deployment
you can change the target namespace for all `kubectl` commands:
```bash
kubectl config set-context --current --namespace=my-app
```
Then you no longer need to specify `-n my-app` with each call. Just remember to
change back the `deault` namespace when you are finished!

!!! Tip
    You can check the current namespace targeted by `kubectl` commands by running `kubectl config get-contexts` (`*` indicates the current namespace) 


## Preparation: Additional Setup

The cluster will need access to our demo deployment manifests, which you can
retrieve from the main repository branch:
```bash
git clone https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes.git
```
!!! Warning
    If you are connected to our router, you will need to temporarily disconnect and use the venue Wifi in order to perform the clone. You can then connect back to our router.

For those running `kubectl` from the nodes over a SSH connection (instead of
from their own device; see [Access The Cluster Directly From Your Laptop](lesson1/exercise3.md#optional-access-the-cluster-directly-from-your-laptop)),
you will need to copy at least the resources subdirectory to the node that you are using. For example,

```bash
scp -r resources/ chef@kmaster:~/
ssh chef@kmaster
ls -l 
---
total 12
drwxr-xr-x 2 chef chef 4096 May 13 04:57 resources
-rwxrwxr-x 1 chef chef 4880 May 10 02:04 setup-rpi-worker.sh
```

While a single person from the group could deploy all the manifests, we
recommend sharing deployments between you so that everyone gets
practice. 

In the following we use `RES_HOME` for where you chose to store the resource folder (`~/resources` above).

Since the cluster is air-gapped, we can't simply retrieve container images from, e.g., Docker Hub. We've put a collection of basic images
to use in this tutorial in the archive `/root/workshop-images.tar` which can be
made accessible to Kubernetes on the nodes with the K3s command

```bash
sudo k3s ctr images import /root/workshop-images.tar
```

<!--If the file is missing from the node, alert or email Lewis and he'll help get the files.  -->

!!! Tip
    For following along at home, or with regular Docker Hub images on an internet-enabled RPi cluster, you will need to change the manifests in the resources folder to directly pull the chosen image. For example, in `./resources/iperf3.yaml`, one would replace `image: workshop-tools:arm64` with `image: iperf3`, and in `./resources/cronjob.yaml`, `image:workshop-tools:arm64` would be replaced with `image: bash`.
