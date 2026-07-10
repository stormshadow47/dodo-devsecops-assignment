#!/usr/bin/env bash
# Generate a self-signed TLS certificate for local dev and create the
# Kubernetes Secret referenced by the Ingress resource (ledger-api-tls).
#
# Usage:
#   ./deploy/scripts/generate-tls-secret.sh
#
# Prerequisites: openssl, kubectl

set -euo pipefail

NAMESPACE="payments"
SECRET_NAME="ledger-api-tls"
HOST="ledger-api.example.com"
DAYS=365

echo "==> Generating self-signed certificate for ${HOST} ..."

openssl req -x509 -nodes -days "${DAYS}" \
  -newkey rsa:2048 \
  -keyout /tmp/tls.key \
  -out /tmp/tls.crt \
  -subj "/CN=${HOST}/O=Dodo Payments Dev" \
  -addext "subjectAltName=DNS:${HOST}"

echo "==> Creating TLS secret in namespace ${NAMESPACE} ..."

kubectl create secret tls "${SECRET_NAME}" \
  --namespace="${NAMESPACE}" \
  --cert=/tmp/tls.crt \
  --key=/tmp/tls.key \
  --dry-run=client -o yaml | kubectl apply -f -

rm -f /tmp/tls.crt /tmp/tls.key

echo "==> Secret '${SECRET_NAME}' created in namespace '${NAMESPACE}'."
echo "    For production, use cert-manager or a real CA-signed certificate."
