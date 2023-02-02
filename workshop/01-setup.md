# Hands-on Hacking K8s Workshop | Section 1: Setup

<!-- TOC -->
* [Hands-on Hacking K8s Workshop | Section 1: Setup](#hands-on-hacking-k8s-workshop--section-1--setup)
  * [Install prerequisite tools](#install-prerequisite-tools)
    * [Docker](#docker)
    * [kind (Kubernetes in Docker)](#kind--kubernetes-in-docker-)
    * [kubectl](#kubectl)
    * [git (optional)](#git--optional-)
    * [Clone/copy kubernetes-goof repo](#clonecopy-kubernetes-goof-repo)
    * [Stand up the cluster and vulnerable deployment](#stand-up-the-cluster-and-vulnerable-deployment)
    * [Sanity tests](#sanity-tests)
  * [Next Step: Start exploiting!](#next-step--start-exploiting-)
<!-- TOC -->

## Install prerequisite tools

### Docker
You will need a container runtime engine running on your workstation for this lesson. While almost any OCI compatible runtime
should work, we will assume you are using Docker installed using one of the following means:
* **Docker Desktop** (Mac / Win / Linux): Go to https://docs.docker.com/get-docker/ and follow the instructions for your platform
* **Docker Engine** (Linux only): Go to https://docs.docker.com/engine/install/#server and follow the instructions for your Linux distribution 

When finished, validate the installation by running `docker run --rm -it hello-world` which should return something similar to the following:
```
$ docker run --rm -it hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
7050e35b49f5: Pull complete
Digest: sha256:7d246653d0511db2a6b2e0436cfd0e52ac8c066000264b3ce63331ac66dca625
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (arm64v8)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

### kind (Kubernetes in Docker)
This lesson uses a **Kubernetes in Docker (kind)** cluster which is a lightweight Kubernetes distribution that runs in containers on your workstation.
Install **kind** per instructions at https://kind.sigs.k8s.io/docs/user/quick-start/

_Note: Make sure you're not already running the built-in Kubernetes that comes with Docker Desktop.
To check this, open the Doctor Desktop dashboard and click the gear icon in the top right. Next click on the Kubernetes icon and ensure that the "Enable Kubernetes" option is toggled off.
If it is enabled, deselect it and click "Apply & Restart"._

![](/Users/eric/work/git/kubernetes-goof/workshop/media/01-docker-desktop-prefs.png)

### kubectl
To interact with our Kubernetes cluster will need the **kubectl** command line tool
If you have Docker Desktop installed, you should already have this tool in your path.
If you do not have it installed, follow the instructions at https://kubernetes.io/docs/tasks/tools/#kubectl
for your platform.

Verify **kubectl** is successfully installed by running `kubectl version` which should return something like this:
```
$ kubectl version
WARNING: This version information is deprecated and will be replaced with the output from kubectl version --short.  Use --output=yaml|json to get the full version.
Client Version: version.Info{Major:"1", Minor:"24", GitVersion:"v1.24.3", GitCommit:"aef86a93758dc3cb2c658dd9657ab4ad4afc21cb", GitTreeState:"clean", BuildDate:"2022-07-13T14:21:56Z", GoVersion:"go1.18.4", Compiler:"gc", Platform:"darwin/arm64"}
Kustomize Version: v4.5.4
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```
### git
The **git** command line tool can be installed in a variety of ways.  For example, on Mac OS you may install it using Apple's developer tools or possibly via homebrew.
If you do not already have it installed, follow the appropriate link on official installation page at https://git-scm.com/downloads

### Clone/copy kubernetes-goof repo
Clone or download an archive of the https://github.com/snyk-labs/kubernetes-goof repository
* git client, ssh method: `git clone git@github.com:snyk-labs/kubernetes-goof.git`
* git client, https method: `git clone https://github.com/snyk-labs/kubernetes-goof.git`
* zip file (no git client necessary): https://github.com/snyk-labs/kubernetes-goof/archive/refs/heads/main.zip

### Stand up the cluster and vulnerable deployment
Now that you have the tools installed, and you have a copy of the workshop repository `cd` into the directory named `setup` and run the `./setup.sh` script to get our cluster up and running and install our workshop application:
```bash
$ ./setup.sh
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.23.6) 🖼
 ✓ Preparing nodes 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Not sure what to do next? 😅  Check out https://kind.sigs.k8s.io/docs/user/quick-start/
configmap/calico-config created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
...
deployment.apps/webadmin created
pod/etcdclient created
waiting for etcdclient pod
waiting for etcdclient pod
waiting for etcdclient pod
pod "etcdclient" deleted
pod/snyky created
waiting for snyky pod
waiting for snyky pod
waiting for snyky pod
pod "snyky" deleted
```

### Sanity tests
1. From your terminal, run `kubectl get nodes` and make sure you see two nodes, both with `Ready` in their status column.

```kubernetes
$ kubectl get nodes
NAME                 STATUS   ROLES                  AGE   VERSION
kind-control-plane   Ready    control-plane,master   39m   v1.23.6
kind-worker          Ready    <none>                 38m   v1.23.6
```
2. In a browser, open http://localhost/webadmin, you should get a page with the header, **Hello, Admin, What command should I run?** and an empty box with the word **NONE** above it.

### Troubleshooting
* If you are getting an nginx 404 Not Found error when trying to open http://localhost/webadmin, this usually is due to an ingress
creation failure.  Try running `kubectl apply -f webadmin_svc_ingress.yaml -n secure` to resolve it.  (There appears to be a race condition in the setup routine that sometimes pops up.)

## [Next Step: Start exploiting!](02a-exploit.md)
