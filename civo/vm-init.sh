#!/bin/bash
cd /tmp

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

curl -LO https://dl.k8s.io/release/v1.24.8/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind

cd ~ubuntu
git clone https://github.com/snyk-labs/kubernetes-goof
cd kubernetes-goof/setup
git checkout civo
chown -R ubuntu:ubuntu ../../kubernetes-goof
su ubuntu ./setup-kubeadm.sh
