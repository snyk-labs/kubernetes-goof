#!/bin/bash
echo "🔑 Creating temporary ssh key"
ssh-keygen -f ./k8s-goof-key -b 2048 -q -N ""
echo -n "   ▪ "; civo sshkey create k8s-goof-key -k ./k8s-goof-key.pub | grep -v "api.github.com"

LOCAL_IP="$(curl -s ifconfig.co/)/32"
echo "🔥 Creating firewall to limit ingress from only $LOCAL_IP"
echo -n "   ▪ "; civo firewall create k8s-goof-fw --create-rules=false | grep -v "api.github.com"
echo -n "   ▪ "; civo firewall rule create k8s-goof-fw -s=1 -e=65535 -p TCP -c $LOCAL_IP | grep -v "api.github.com"
echo -n "   ▪ "; civo firewall rule create k8s-goof-fw -s=1 -e=65535 -p TCP -d egress | grep -v "api.github.com"

echo "🔨 Provisioning instances"
# echo -n "  ▪ "; civo instance create -s k8s-goof -u ubuntu -i g3.medium -k k8s-goof-key -l k8s-goof-fw --diskimage=ubuntu-jammy --script ./vm-init.sh -w -p=create | grep -v "api.github.com"
echo -n "  ▪ "; civo instance create -s k8s-goof-control -u ubuntu -i g3.medium -k k8s-goof-key --diskimage=ubuntu-jammy --script ./kube-init.sh -p=create | grep -v "api.github.com"
echo -n "  ▪ "; civo instance create -s k8s-goof-worker -u ubuntu -i g3.medium -k k8s-goof-key --diskimage=ubuntu-jammy --script ./kube-init.sh -w -p=create | grep -v "api.github.com"

PUBLIC_IP1="$(civo instance show k8s-goof-control -o custom -f public_ip | tail -1)"
PRIVATE_IP1="$(civo instance show k8s-goof-control -o custom -f private_ip | tail -1)"
PUBLIC_IP2="$(civo instance show k8s-goof-worker -o custom -f public_ip | tail -1)"

echo -n "⌚️  Waiting for control plane host to start up..."
while ! ssh -q -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP1 -i k8s-goof-key cloud-init status --wait
do
    sleep 5
    echo -n "."
done

echo
echo "🏗️ Standing up Kubernetes control plane"
a=$(cat k8s-goof-key.pub | tr '[:upper:]' '[:lower:]'); TOKEN=${a:7:7}.${a:14:16};

scp -i k8s-goof-key kubeadm-config.yaml ubuntu@$PUBLIC_IP1:/tmp/kubeadm-config.yaml
ssh ubuntu@$PUBLIC_IP1 -i k8s-goof-key sudo kubeadm init --config /tmp/kubeadm-config.yaml --token $TOKEN

echo -n "⌚️  Waiting for worker host to start up..."
while ! ssh -q -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP2 -i k8s-goof-key cloud-init status --wait
do
    sleep 5
    echo -n "."
done

echo
echo "🤝 Joining Kubernetes worker node"
ssh ubuntu@$PUBLIC_IP2 -i k8s-goof-key sudo kubeadm join $PRIVATE_IP1:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification

echo "🥷🏻 Grabbing kube config"
mkdir -p .kube
ssh -q ubuntu@$PUBLIC_IP1 -i k8s-goof-key "sudo cp /etc/kubernetes/admin.conf ~ubuntu/admin.conf; sudo chown ubuntu:ubuntu ~ubuntu/admin.conf"
scp -i k8s-goof-key ubuntu@$PUBLIC_IP1:admin.conf .kube/config

echo "🥳 Done!"
echo


# echo -n "⌚️ Waiting for demo app to become available (at $PUBLIC_IP)..."
# while ! curl -s http://$PUBLIC_IP/webadmin
# do
#   sleep 5
#   echo -n "."
# done


# echo "😈 Vulnerable app running at http://$PUBLIC_IP/webadmin"
echo "💻 Control plane shell access via: ssh ubuntu@$PUBLIC_IP1 -i k8s-goof-key"
echo "💻 Worker shell access via: ssh ubuntu@$PUBLIC_IP2 -i k8s-goof-key"