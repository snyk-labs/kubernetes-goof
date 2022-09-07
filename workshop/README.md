# Hands-on Hacking K8s Workshop

Welcome to our hands-on workshop for demonstrating some common attack vectors and how to
mitigate or otherwise minimize their blast radius.

This workshop is tailored for an in-person, instructor led presentation but feel free to
experiment with the examples and open issues here in GitHub if you have questions, or to make
suggestions for improvements.

---
## WARNING! | ACHTUNG! | ¡PRECAUCIÓN! | !AVERTISSEMENT!
Many of the applications that are part of this workshop are **highly dangerous**
and are purposely built with vulnerabilities! Please, **do not deploy these examples to
clusters that you don't want to have attacked!**

In other words, only deploy these to local/sandboxed clusters for the sole purpose of experimentation.
Examples of places you should **NOT** deploy this to:
* your developer servers
* your QA environment
* not your company's cloud account

We take no responsibility for exploitation or damages caused by deploying anything from this
repository (or the associated container images) to your personal or organization's infrastructure (private or public).

## You have been warned!

---

## Outline:
### [1. Setup](01-setup.md)
Installing prerequisite tools and standing up the vulnerable cluster.
### [2. Exploit](02a-exploit.md)
Walking through a progressive exploitation of the cluster, broken into sub-sections:
  * [Part 1: Examining the vulnerability](02a-exploit.md)
  * [Part 2: Accessing the api-server](02b-exploit.md)
  * [Part 3: Cluster fact finding](02c-exploit.md)
  * [Part 4: Setting up a beachhead in the cluster](02d-exploit.md)
  * [Part 5: Exploring beyond our Namespace](02e-exploit.md)
  * [Part 6: Escaping our Namespace](02f-exploit.md)
  * [Part 7: Owning the cluster](02g-exploit.md)
### [3. Mitigation Discussion](03-mitigations.md)
### [4. Next Steps/Resources](04-next-steps.md)