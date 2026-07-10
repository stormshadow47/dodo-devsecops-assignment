#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"


echo "Creating namespace..."


kubectl apply -f deploy/namespace.yaml


# Ensure kubeseal is installed


if ! command -v kubeseal >/dev/null 2>&1; then
    echo "kubeseal not found."
    echo "Installing kubeseal..."

    VERSION="0.28.0"

    wget -q \
      "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${VERSION}/kubeseal-${VERSION}-linux-amd64.tar.gz"

    tar -xzf "kubeseal-${VERSION}-linux-amd64.tar.gz"

    sudo install -m755 kubeseal /usr/local/bin/

    rm kubeseal
    rm "kubeseal-${VERSION}-linux-amd64.tar.gz"

    echo "kubeseal installed successfully."
fi


# Generate Sealed Secret


echo
echo "Generating Sealed Secret..."

if [ ! -f "$PROJECT_ROOT/.env.local" ]; then
    echo ".env.local not found."
    echo
    echo "Create it like this:"
    echo "VAULT_AUTH_KEY=your_actual_vault_auth_key"
    exit 1
fi

set -a
source "$PROJECT_ROOT/.env.local"
set +a

if [ -z "${VAULT_AUTH_KEY:-}" ]; then
    echo "VAULT_AUTH_KEY is empty."
    exit 1
fi

kubectl create secret generic ledger-api-secrets \
    --namespace payments \
    --from-literal=VAULT_AUTH_KEY="$VAULT_AUTH_KEY" \
    --dry-run=client \
    -o yaml > secret.yaml

kubeseal \
    --controller-name sealed-secrets-controller \
    --controller-namespace kube-system \
    --format yaml \
    < secret.yaml \
    > deploy/04-sealedsecret.yaml

rm secret.yaml

kubectl apply -f deploy/04-sealedsecret.yaml


kubectl apply -f deploy/01-serviceaccount.yaml
kubectl apply -f deploy/02-rbac.yaml
kubectl apply -f deploy/03-configmap.yaml
kubectl apply -f deploy/05-service.yaml
kubectl apply -f deploy/06-deployment-ledger.yaml
kubectl apply -f deploy/08-neighbour.yaml
kubectl apply -f deploy/07-ingress.yaml
kubectl apply -f deploy/09-networkpolicy.yaml
kubectl apply -f deploy/10-kyverno-policies.yaml
kubectl apply -f deploy/11-rbac-personas.yaml

