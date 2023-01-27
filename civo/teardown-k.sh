#!/bin/bash

echo "💀 Terminating instance"
civo instance remove -y k8s-goof-control | grep -v "api.github.com"
civo instance remove -y k8s-goof-worker | grep -v "api.github.com"

echo "💀 Removing firewall"
civo firewall remove -y k8s-goof-fw | grep -v "api.github.com"

echo "💀 Removing temporary ssh key"
civo sshkey remove -y k8s-goof-key | grep -v "api.github.com"
rm ./k8s-goof-key*

echo "💀 Removing .kube folder"
rm -rf .kube