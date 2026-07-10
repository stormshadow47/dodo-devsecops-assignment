#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "Creating Kubernetes Cluster"


kind delete cluster --name ledger-api || true

kind create cluster \
  --name ledger-api \
  --config deploy/kind-config.yaml

echo
echo "Installing NGINX Ingress..."

kubectl apply -f \
https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for ingress deployment..."

kubectl rollout status \
    deployment/ingress-nginx-controller \
    -n ingress-nginx \
    --timeout=180s

echo
echo
echo "Installing Sealed Secrets..."

kubectl apply -f \
https://github.com/bitnami-labs/sealed-secrets/releases/latest/download/controller.yaml

kubectl rollout status deployment/sealed-secrets-controller \
    -n kube-system \
    --timeout=180s

echo



echo "Installing Kyverno..."

kubectl create -f \
https://github.com/kyverno/kyverno/releases/download/v1.12.5/install.yaml

kubectl rollout status deployment/kyverno-admission-controller -n kyverno
kubectl rollout status deployment/kyverno-background-controller -n kyverno
kubectl rollout status deployment/kyverno-cleanup-controller -n kyverno
kubectl rollout status deployment/kyverno-reports-controller -n kyverno

echo
echo "Cluster Ready."