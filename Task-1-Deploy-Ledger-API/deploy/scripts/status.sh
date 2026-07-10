#!/usr/bin/env bash

echo
echo "Pods"
kubectl get pods -A

echo
echo "Services"
kubectl get svc -A

echo
echo "Ingress"
kubectl get ingress -A

echo
echo "Secrets"
kubectl get secrets -n payments

echo
echo "Network Policies"
kubectl get networkpolicy -n payments

echo
echo "Deployments"
kubectl get deploy -A