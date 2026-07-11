# Dodo Payments – Security & DevOps Assessment

This repository contains my solution for the Dodo Payments Security & DevSecOps Engineer Technical Assessment. The assignment focuses on securing a Kubernetes workload, building a secure software supply chain, and adopting GitOps practices.

## Repository Structure

```
.
├── Task-1-Deploy-Ledger-API/
│   ├── deploy/
│   └── README.md
│
├── Task-2-Secure-CICD-Pipeline/
│   ├── .github/workflows/
│   ├── argocd/
│   └── README.md
│
└── README.md
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

Due to time constraints, documentation created for:

- Task 3 - Service Mesh & Zero-Trust (Istio)
- Task 4 - Reconnaissance & Penetration Testing

