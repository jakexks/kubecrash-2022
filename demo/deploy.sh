#!/usr/bin/env bash -xe

pushd ../
docker build -t kubecrash .
popd

kind delete cluster --name kubecrash || true
kind create cluster --name kubecrash --config kind-cluster.yaml
kind --name kubecrash load docker-image kubecrash 

# helm upgrade --install ingress-nginx ingress-nginx \
#   --repo https://kubernetes.github.io/ingress-nginx \
#   --namespace ingress-nginx --create-namespace --values nginx.values.yaml
kubectl apply -f supersecureapp.yaml
kubectl apply -f auth-provider.yaml
kubectl apply -f oidc-provider.yaml
kubectl apply -f oauth2-proxy.yaml
# helm upgrade --install  vouch vouch/vouch --values vouch-values.yaml

