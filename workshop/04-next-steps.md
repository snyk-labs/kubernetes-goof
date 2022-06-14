# Hands-on Hacking K8s Workshop | Section 4: Next Steps

<!-- TOC -->
* [Hands-on Hacking K8s Workshop | Section 4: Next Steps](#hands-on-hacking-k8s-workshop--section-4--next-steps)
    * [ServiceAccount token auto-mount changes in v1.24](#serviceaccount-token-auto-mount-changes-in-v124)
    * [PSP removal in v1.25](#psp-removal-in-v125)
    * [Network Policy complexities](#network-policy-complexities)
    * [Community resources](#community-resources)
<!-- TOC -->

### ServiceAccount token auto-mount changes in v1.24
In the v1.25 release of Kubernetes, there was a change to move the `LegacyServiceAccountTokenNoAutoGeneration` feature flag into beta
which means that it is now set to `true` by default. This **does not** change the fact that serviceaccount tokens will be mounted as secrets in the filessystems of all new pods
by default. It's actual effect is that there will not be a Kubernetes Secret created for these tokens going forward.
It is still important to consider setting `automountServiceAccountToken: false` for all serviceaccounts and/or pods wherever
possible in your deployments.

### PSP removal in v1.25
The Pod Security Policy API was deprecated in v1.21 and has recently been removed from v1.25 forward. In it's absence,
consider one (or more) of the following projects to back-fill the functionality PSPs provided
* Pod Security Admission (new and the main replacement for PSP)
  * History: Blog [PodSecurityPolicy Deprecation: Past, Present, and Future](https://kubernetes.io/blog/2021/04/06/podsecuritypolicy-deprecation-past-present-and-future/) -Tabitha Sable (Kubernetes SIG Security) 
  * [K8s Docs](https://kubernetes.io/docs/concepts/security/pod-security-admission/) 
* Kyverno
  * [Project Page](https://kyverno.io/)
  * [Policies](https://kyverno.io/policies/)
* OPA Gatekeeper
  * [Project Page](https://github.com/open-policy-agent/gatekeeper)
  * [Policys](https://github.com/open-policy-agent/gatekeeper-library)

### Network Policy complexities
* [Ahmed Alp Balkan's Kubernetes Network Policy Recipes](https://github.com/ahmetb/kubernetes-network-policy-recipes)
* Cilium editor/visualizer: https://networkpolicy.io/
* CNI-specific policies
* NetworkPolicy++
* [Hierarchical Namespaces](https://github.com/kubernetes-sigs/hierarchical-namespaces)
  * "Allows all workloads within a subtree to be restricted to the same ingress/egress rules"
  * Parent namespace NetworkPolicy can be propagated to its children 

### Community resources
* [K8s SIG-Security](https://github.com/kubernetes/sig-security)
* [CNCF TAG-Security](https://github.com/cncf/tag-security)
* [K8s SIG-Nework](https://github.com/kubernetes/community/tree/master/sig-network)
* [OpenSSF](https://openssf.org/)


