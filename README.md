# Demo Setup

This document details the setup for the demo environment. In the git repository you will also find a `setup.sh` script which will automate the entire process.

## Pre-requisites

Tested on Docker Desktop 4.23.0 and kind 0.19.0

### [Kind](https://kind.sigs.k8s.io/) 

`brew install kind`

### [Kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)

`brew install kubectl`

### [Krew](https://krew.sigs.k8s.io/)

[Install](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)

### Krew plugins

**[Access Matrix](https://github.com/corneliusweig/rakkess)**

`kubectl krew install access-matrix`

**[Net Forward](https://github.com/antitree/krew-net-forward)**

`kubectl krew install net-forward`

**[Who Can](https://github.com/aquasecurity/kubectl-who-can)**

`kubectl krew install who-can`


## Create Kind Cluster

We are going to create a Kubernetes cluster using Kind, with some custom configuration to add support for Ingress controllers.

`kind create cluster --config kind_ingress.yaml`

At this point the cluster will not actually deploy, as the PodSecurityPolicy admission controller is enabled without any policies in place. In this scenario all deployments are blocked so the control plane will not deploy. 

When it has completed you should expect to see something like :

```console
% kubectl get pods --all-namespaces            
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
kube-system          coredns-f9fd979d6-cl9zh                      1/1     Running   0          51s
kube-system          coredns-f9fd979d6-x2gdt                      1/1     Running   0          51s
kube-system          etcd-kind-control-plane                      1/1     Running   0          64s
kube-system          kindnet-d7xth                                1/1     Running   0          61s
kube-system          kindnet-w8d66                                1/1     Running   0          61s
kube-system          kube-apiserver-kind-control-plane            1/1     Running   0          79s
kube-system          kube-controller-manager-kind-control-plane   1/1     Running   0          76s
kube-system          kube-proxy-k5g69                             1/1     Running   0          61s
kube-system          kube-proxy-mt52w                             1/1     Running   0          61s
kube-system          kube-scheduler-kind-control-plane            1/1     Running   0          75s
local-path-storage   local-path-provisioner-78776bfc44-xjqhk      1/1     Running   0          51s
```

```console
% kubectl get nodes
NAME                 STATUS   ROLES    AGE     VERSION
kind-control-plane   Ready    master   3m47s   v1.19.1
kind-worker          Ready    <none>   3m19s   v1.19.1
```

Now we need to set up the Ingress controller within its own namespace :

`kubectl apply -f ingress_ns_role.yaml`

Next we can install the Nginx ingress controller :

`kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml`

At this point we need to wait until the Ingress controller pod is fully deployed :

```console
% kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
pod/ingress-nginx-controller-c7c5dfc9f-dbb57 condition met
```
The cluster is now functioning correctly. 

## Create the vulnerable environment

Now we need to set up the environment, including our configuration vulnerabilities. Firstly, set up the secure namespace - this will create the namespace, and bind all Service Accounts from that namespace to the restricted Pod Security Policy.

`kubectl apply -f secure_ns_role.yaml`

Next we will create the service account within the secure namespace. This will also introduce a vulnerability in that we will allow that service account to do a wide variety of actions *within* the specific namespace. This is a fairly common assumption but as we will show can give an attacker the ability to widen the blast radius of an exploit. 

`kubectl apply -f webadmin_user.yaml -n secure`

Next we will introduce a second vulnerability, allowing this user to query the endpoints of the API server. Again this wouldn't necessarily be an obvious issue, but will allow an attacker to gain additional information about the cluster.

`kubectl apply -f webadmin_allow_role_to_see_endpoints.yaml`

Now we will deploy the vulnerable application into the secure namespace. 

`kubectl apply -f webadmin_deployment.yaml -n secure`

We should see the pod running in the secure namespace :

```console
% kubectl get pods -n secure
NAME                        READY   STATUS    RESTARTS   AGE
webadmin-57f55c596d-z5b9b   1/1     Running   0          3s
```
Now the vulnerable application is running, we need to expose it outside of the cluster. For this, we need a Service and an Ingress :

`kubectl apply -f webadmin_svc_ingress.yaml -n secure`

Note in the Ingress configuration that we rewrite the path back to /, since without this the Ingress controller will just pass the /webadmin path on to the application and we will then get a 404 as the app is only listening on the root.

```console
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: webadmin-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /webadmin
        backend:
          serviceName: webadmin
          servicePort: 5000
```

At this point you should be able to [view](http://localhost/webadmin) the vulnerable application in your browser.

Next we will configure the default namespace, and allow service accounts in this namespace to access the privileged Pod Security Policy. Again this is a vulnerability, based on the assumption that we are controlling all other namespaces with namespace specific role bindings. 

`kubectl apply -f default_ns_role.yaml`

Next we will add the same service account and roles as we have in our secure namespace :

`kubectl apply -f webadmin_user.yaml`

And now we add an instance of the vulnerable application to the default namespace :

`kubectl apply -f webadmin_deployment.yaml`

```console
 % k get pods
NAME                        READY   STATUS    RESTARTS   AGE
webadmin-57f55c596d-fhqqw   1/1     Running   0          3s
```

So this basically gives us a mirrored setup in the default namespace as we have in the secure namespace, but in default we are not enforcing the restricted Pod Security Policy.

