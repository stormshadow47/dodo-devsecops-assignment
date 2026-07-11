# Dodo Payments – Security & DevOps Assessment

## Overview

This repository contains my implementation of the Dodo Payments Security & DevSecOps assessment.

The project focuses on securing a Kubernetes workload, implementing a secure CI/CD pipeline with supply chain security controls, and adopting GitOps using ArgoCD.

## Repository Structure

```
.
├── Task-1-Deploy-Ledger-API/
│   ├── app/
│   └── deploy/
│
└── Task-2-Secure-CICD-Pipeline/
    ├── .github/workflows/
    └── argocd/
```


## Completed Tasks
### Task 1 – Deploy & Harden the Workload

Hardened ployment of the Ledger API with Kubernetes security best practices.

Implemented:

- Hardened Deployment manifests
- Non-root containers
- Read-only root filesystem
- Dropped Linux capabilities
- RuntimeDefault seccomp profile
- Liveness & Readiness probes
- Resource requests & limits
- Dedicated Service Accounts
- Least-privilege RBAC
- ConfigMaps
- Sealed Secrets
- Network Policies
- Kyverno admission policies
- Reporting neighbour service
- Automated deployment using setup.sh

## Task 2 - Secure-CICD-Pipeline

A production-oriented GitHub Actions pipeline securing the software supply chain from commit to Kubernetes deployment.

Implemented:

- Semgrep SAST
- Gitleaks secret scanning
- Trivy filesystem scan
- Trivy image scan
- GHCR image publishing
- Cosign keyless image signing
- Signature verification
- Provenance attestation
- Attestation verification
- ArgoCD GitOps deployment
- Automatic Sync
- Drift Detection
- Self Healing

## Technologies Used

- Kubernetes
- Docker
- GitHub Actions
- ArgoCD
- Kyverno
- Trivy
- Semgrep
- Gitleaks
- Cosign
- Sealed Secrets
- GHCR

### Notes:
Images are signed using Cosign keyless signing with GitHub OIDC.
Secrets are encrypted using Sealed Secrets.
Kyverno enforces admission policies for workload security.
ArgoCD provides GitOps-based deployment, drift detection, and self-healing.

Due to time constraints, documentation created for:

- Task 3 - Service Mesh & Zero-Trust (Istio)
- Task 4 - Reconnaissance & Penetration Testing

