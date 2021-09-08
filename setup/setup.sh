#!/bin/bash

# Create the cluster with PSP and Ingress support
kind create cluster --config kind_psp_ingress.yaml

# Add the PSP's
kubectl apply -f privileged_psp.yaml
kubectl apply -f restricted_psp.yaml

# Add the Cluster Roles
kubectl apply -f cluster_roles.yaml

# Add the Role Bindings
kubectl apply -f role_bindings.yaml

# Wait for the nodes to become ready
kubectl wait --for=condition=ready node --all

# Apply the role for the Ingress controller
kubectl apply -f ingress_ns_role.yaml

# Configure and install the Ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/legacy/deploy/static/provider/kind/deploy.yaml

# Wait for the Ingress controller to become ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Create and configure the 'secure' namespace
kubectl apply -f secure_ns_role.yaml

# Create and configure the webadmin service account in the secure namespace
kubectl apply -f webadmin_user.yaml -n secure

# Allow the webadmin role to view the cluster endpoints
kubectl apply -f webadmin_allow_role_to_see_endpoints.yaml

# Deploy the vulnerable app into the secure namespace
kubectl apply -f webadmin_deployment.yaml -n secure

#FIXME DO WE NEED TO WAIT HERE ??

# Create the Service and Ingress for the vulnerable app in the secure namespace
kubectl apply -f webadmin_svc_ingress.yaml -n secure

# Create the role for the default namespace
kubectl apply -f default_ns_role.yaml

# Create the webadmin service account in the default namespace
kubectl apply -f webadmin_user.yaml

# Deploy the vulnerable app into the default namespace
kubectl apply -f webadmin_deployment.yaml



