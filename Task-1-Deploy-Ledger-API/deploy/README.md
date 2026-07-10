# Production-Grade Deployment Guide

This directory contains hardened Kubernetes manifests for deploying ledger-api with security best practices.

## Deployment Order

Apply manifests in numerical order:

```bash
# 1. Create namespace with PSS labels
kubectl apply -f namespace.yaml

# 2. Create ServiceAccount for ledger-api
kubectl apply -f 01-serviceaccount.yaml

# 3. Create RBAC (Role + RoleBinding)
kubectl apply -f 02-rbac.yaml

# 4. Create ConfigMap for non-sensitive config
kubectl apply -f 03-configmap.yaml

# 5. Create SealedSecret
kubectl apply -f 04-sealedsecret.yaml

# 6. Deploy hardened ledger-api
kubectl apply -f 05-deployment-hardened.yaml

# 7. Create Service
kubectl apply -f service.yaml

# 8. Create Ingress (optional)
kubectl apply -f 06-ingress.yaml

# 9. Deploy hardened neighbour service
kubectl apply -f 07-neighbour-hardened.yaml

# 10. Apply Kyverno policies (cluster-wide)
kubectl apply -f 08-kyverno-policies.yaml

# 11. Apply RBAC personas
kubectl apply -f 09-rbac-personas.yaml

# 12. Apply NetworkPolicies (zero-trust networking)
kubectl apply -f 11-networkpolicy.yaml

# 13. Generate TLS secret for Ingress (local dev)
./scripts/generate-tls-secret.sh
```

## Security Hardening Summary

### Container Security
- ✅ Non-root user (UID 1000)
- ✅ Read-only root filesystem
- ✅ All capabilities dropped
- ✅ seccomp RuntimeDefault profile
- ✅ No privilege escalation

### Resource Management
- ✅ CPU/memory requests and limits
- ✅ Liveness and readiness probes
- ✅ 3 replicas for high availability

### Secrets Management
- ✅ Secrets removed from git
- ✅ SealedSecrets for secret storage
- ✅ ConfigMap for non-sensitive configuration
- ⚠️ Re-seal `04-sealedsecret.yaml` against your cluster's controller cert before applying (the committed blob is a placeholder)

### Application Design
- ✅ Stateless service — no transaction storage; `GET /transactions` returns 501

### RBAC
- ✅ Dedicated ServiceAccount (no default SA)
- ✅ Least-privilege Role (no runtime Kubernetes API permissions)
- ✅ automountServiceAccountToken: false
- ✅ Persona-based RBAC (developer/operator/admin)

### Admission Control
- ✅ Pod Security Standards (restricted) enforced on namespace
- ✅ Kyverno policies:
  - Disallow root user
  - Disallow :latest tags
  - Require signed images (cosign keyless via Sigstore/Rekor)
- ⚠️ Update `08-kyverno-policies.yaml` image references and cosign attestor subjects to match your GitHub org/repo before enforcing signed-image policy locally

### Network Security
- ✅ Default deny all ingress and egress
- ✅ Ingress to ledger-api only from ingress-nginx namespace
- ✅ Ingress to reporting only from within the payments namespace
- ✅ Egress from ledger-api restricted to DNS (port 53) and vault (port 443)
- ✅ Egress from reporting restricted to DNS only
- ⚠️ For production, restrict vault egress to the vault's specific CIDR

### TLS / Ingress
- ✅ Ingress enforces SSL redirect (`ssl-redirect`, `force-ssl-redirect`)
- ✅ TLS secret `ledger-api-tls` required by Ingress
- ⚠️ Run `./scripts/generate-tls-secret.sh` for local dev (self-signed cert)
- ⚠️ For production, use cert-manager or a real CA-signed certificate

### Application Security
- ✅ Removed `/fetch` endpoint (SSRF vulnerability — allowed arbitrary URL fetching)
- ✅ Removed `/import` endpoint (unnecessary attack surface — parsed untrusted YAML)
- ✅ Removed `PyYAML` dependency (no longer needed)

## Verification

### Check security context:
```bash
kubectl get deployment ledger-api -n payments -o yaml | grep -A 20 securityContext
```

### Check PSS compliance:
```bash
kubectl get namespace payments -o yaml | grep pod-security
```

### Check Kyverno policies:
```bash
kubectl get clusterpolicies -n kyverno
```

### Test admission rejection:
```bash
kubectl apply -f deployment.yaml  # Original insecure deployment
# Should be rejected by Kyverno/PSS
```

## Secret Setup

### Using SealedSecrets
```bash
# Install kubeseal
# https://github.com/bitnami-labs/sealed-secrets

# Create a local, untracked Secret manifest from values stored outside git.
kubectl create secret generic ledger-api-secrets \
  --from-literal=TOKENIZATION_VAULT_TOKEN="${TOKENIZATION_VAULT_TOKEN}" \
  --dry-run=client -o yaml > secret.yaml

# Seal it
kubeseal --format yaml --cert=pub-cert.pem < secret.yaml > 04-sealedsecret.yaml
```

## RBAC Personas

| Role | Permissions | Use Case |
|------|-------------|----------|
| Developer | Deploy, debug, manage secrets | Application developers |
| Operator | Scale, monitor, view logs | SRE/Ops teams |
| Admin | Full namespace control | Team leads/Platform engineers |

## Troubleshooting

### Deployment fails with PSS error
Ensure the hardened deployment is used, not the original:
```bash
kubectl apply -f 05-deployment-hardened.yaml
```

### SealedSecret not decrypting
Check the SealedSecret controller is running:
```bash
kubectl get pods -n sealed-secrets
```

### Kyverno policy blocking deployment
Check policy violations:
```bash
kubectl get policyreport -n payments
```

## Original vs Hardened Comparison

| Feature | Original | Hardened |
|---------|----------|----------|
| ServiceAccount | default (excessive) | dedicated (least-privilege) |
| Secrets | plaintext in git | SealedSecrets |
| securityContext | none | non-root, read-only, drop ALL |
| seccomp | none | RuntimeDefault |
| Resources | none | requests/limits |
| Probes | none | liveness/readiness |
| PSS | baseline | restricted |
| Image tag | :starter | specific tag (ghcr.io) |
| NetworkPolicy | none | default-deny + selective allow |
| TLS | none | Ingress with TLS + SSL redirect |
| Attack surface | /fetch (SSRF), /import (YAML parse) | endpoints removed |
