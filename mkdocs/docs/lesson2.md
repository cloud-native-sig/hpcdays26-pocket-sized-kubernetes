# Lesson 2 — Using your cluster

In this lesson, you'll begin to deploy a range of resources onto the cluster. We are still working with an air-gapped installation and so there is some limitations to what we can apply. Regardless, we will still be able to cover important topics like;

* Services, networking and Monitoring
* Resource Management and Failure Recovery
* Persistent Storage
* Jobs and Batch Execution

By the end of this session and workshop, the aim is for you to be able to see some of the benefits to using Kubernetes and how this relates to HPC environments. 

## Some additional setup steps preparations

Before you connect to the router, in this next session the cluster will need access to our demonstration deployment manifests. If you are using your local computer and have kubectl access to the cluster, you only need to checkout the git branch locally, if you haven't already.

```bash
git clone https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes.git
```

If you are accessing the nodes via ssh and using kubectl from here, checkout the repo, connect to our router, and then copy at least the resources repository to the node youre using. For example

```bash
git clone https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes.git
scp -r resources/ chef@kmaster:~/
ssh chef@kmaster
ls -l 
```

```text
total 12 \n
drwxr-xr-x 2 chef chef 4096 May 13 04:57 resources
-rwxrwxr-x 1 chef chef 4880 May 10 02:04 setup-rpi-worker.sh
```

Only one person per group will *need* to deploy manifetes, but it may be useful for everyone to have visibility of the code, and to share the hands-on practice. We will use `RES_HOME` throughout the lessons for where you chose to store the resource folder.

As mentioned before, the cluster is air-gapped, so we need install images differently. For these clusters, you'll use a set of pre-loaded images since the pods wont be able to access them directly from Docker Hub itself.

Each node should have a file present at  /root/workshop-images.tar and you can load it onto that nodes memory using

```bash
sudo k3s ctr images import /root/workshop-images.tar
```

If the file is missing from the node, alert or email Lewis and he'll help get the files.  

For following along at home, or with regular Docker Hub images on an internet-enabled RPi cluster, you would need to change the manifests in the resources folder to directly pull the chosen image. E.g. in ./resources/iperf3.yaml, replace `image: workshop-tools:arm64` with `image: iperf3`, or in ./resources/cronjob.yaml, replace `image:workshop-tools:arm64` with `image: bash`.
