# Lesson 1 — Building your cluster

In this lesson we’ll assemble a small Kubernetes cluster using Raspberry Pis and K3s. By the end of the session, each group should have a functioning multi-node cluster that you can interact with using `kubectl`.

Along the way we’ll:

* connect to the Raspberry Pis over SSH,
* install a Kubernetes control plane,
* join worker nodes to the cluster,
* and take a first look at the resources Kubernetes creates behind the scenes.

This session is intentionally hands-on, so expect to spend most of the time in the terminal exploring the cluster directly.

Getting Ready:

* Split into roughly even groups per cluster and introduce yourself
* Check out the [tutorial github repository](https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes#) and (optionally) follow along on the [GitHub Pages](https://cloud-native-sig.github.io/hpcdays26-pocket-sized-kubernetes/introduction/)
* Open a terminal application with a working SSH client 
<!--* There should be plenty of opportunities for asking questions during the workshop. If Piper or Lewis are presenting, please use [mentimeter?](https://www.mentimeter.com/) to track questions.-->
