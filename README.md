# Dodo Payments – Security & DevOps Assessment

## Overview

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
- Images are signed using Cosign keyless signing with GitHub OIDC.
- Secrets are encrypted using Sealed Secrets.
- Kyverno enforces admission policies for workload security.
- ArgoCD provides GitOps-based deployment, drift detection, and self-healing.

## Planned Approach for Tasks 3 & 4

Tasks 3 and 4 were not completed within the 3-day window as I prioritized completing and fully testing Task 1 and 2. Below is the approach I would have taken.

### Task 3 — Service Mesh & Zero-Trust (Istio)

- **Install:** Install Istio using `istioctl install --set profile=default`, label the `payments` namespace for sidecar injection, and bring `ledger-api` and `reporting` into the mesh.
- **mTLS:** Apply a `PeerAuthentication` resource in `STRICT` mode at the namespace scope. Validation would be performed using `istioctl authn tls-check` and by sending a plaintext (non-mTLS) request from a pod outside the mesh, expecting the connection to be rejected.
- **Authorization:** Start with a default-deny `AuthorizationPolicy` (empty spec, no rules) in the namespace, then add explicit allow rules keyed on workload identity (`source.principals` using the SPIFFE identity derived from each ServiceAccount) rather than IP/CIDR. Validation would include testing with an unauthorized pod to confirm traffic is blocked while ensuring `reporting` can successfully communicate with `ledger-api`.
- Certificates are issued by Istiod (acting as CA) via SDS, auto-rotated roughly every 24h, with Istiod's self-signed root CA as the trust root (or an external CA via cacerts in production).
- **Defense-in-depth:** Layer a Kubernetes `NetworkPolicy` (default-deny + explicit allows) underneath the service mesh. Istio's `AuthorizationPolicy` would enforce identity-based access control at Layer 7, while `NetworkPolicy` would provide Layer 3/4 network segmentation, giving complementary protection against different failure scenarios.


### Task 4 — Reconnaissance & Penetration Testing

**Part A:**

- Enumerate subdomains of `dodopayments.tech` using `crt.sh`, `subfinder`, `amass`, and `assetfinder`.
- Fingerprint live hosts using `httpx` and `whatweb`, and assess TLS posture with `testssl.sh`.
- Compile an attack surface inventory covering exposed subdomains, detected technologies, TLS configuration, and a risk assessment of the most likely attack paths.

**Part B:**

- Run `nuclei` for known CVE and misconfiguration templates, `ffuf` for endpoint discovery, and perform manual testing with Burp Suite or OWASP ZAP covering common OWASP Top 10 categories including Broken Access Control, SQL Injection, XSS, SSRF, authentication, session management, and secrets exposure.
- Where appropriate, validate potential injection findings using `sqlmap` in a rate-limited, non-destructive manner.
- Structure the report with an executive summary, methodology, findings (including CVSS v3.1 score, affected endpoint, reproduction steps, impact, and remediation), followed by an overall risk ranking.




