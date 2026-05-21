# Lesson 1 — Building your cluster

In this lesson we’ll assemble a small Kubernetes cluster using Raspberry Pis and K3s. By the end of the session, each group should have a functioning multi-node cluster that you can interact with using kubectl.

Along the way we’ll:

* connect to the Raspberry Pis over SSH,
* install a Kubernetes control plane,
* join worker nodes to the cluster,
* and take a first look at the resources Kubernetes creates behind the scenes.

This session is intentionally hands-on, so expect to spend most of the time in the terminal exploring the cluster directly.

*Getting Ready* :

* Split into even groups per cluster, introduce yourself to the group you'll be working with for today.
* Checkout the [workshop github](https://github.com/cloud-native-sig/hpcdays26-pocket-sized-kubernetes#)
* (optionally) Following along with the [GitHub Pages](https://cloud-native-sig.github.io/hpcdays26-pocket-sized-kubernetes/introduction/)
* There should be plenty of opportunities for asking questions during the workshop. If Piper or Lewis are presenting, please use [mentimeter?](https://www.mentimeter.com/) to track questions.

## Acknowledgements

This workshop is delivered by the Cloud-Native SIG team with support from the Computational Abilities Knowledge Exchange Network+ (CAKE).

CAKE received funding through the UKRI Digital Research Infrastructure Programme under project reference UKRI1799.

Contributors:

* Piper Fowler-Wright — Rosalind Franklin Institute
* Lewis Sampson — STFC / DAFNI

Documentation:

* [Cloud Native SIG](https://cloudnative-sig.ac.uk/?utm_source=chatgpt.com)
* [K3s Documentation](https://docs.k3s.io/?utm_source=chatgpt.com)
* [Kubernetes Documentation](https://kubernetes.io/docs/home/?utm_source=chatgpt.com)

Links:

* [DAFNI](https://dafni.ac.uk/)
* [CAKE](https://www.cake.ac.uk/)
* [RFI ARC](https://www.rfi.ac.uk/focus/platforms/advanced-research-computing/)
