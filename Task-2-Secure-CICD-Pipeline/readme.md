# Task 2 – Secure CI/CD Pipeline & GitOps

## Overview

This task implements a secure software supply chain for the Ledger API using GitHub Actions, GitHub Container Registry (GHCR), Cosign keyless signing, Kyverno policy enforcement, and ArgoCD GitOps.

The pipeline performs automated security validation before publishing container images and demonstrates GitOps deployment with drift detection and self-healing.

---

## Architecture

```
                          Developer
                              │
                       Push to GitHub
                              │
                              ▼
                     GitHub Actions Pipeline
                              │
      ┌───────────────────────┼────────────────────────┐
      │                       │                        │
      ▼                       ▼                        ▼
  Semgrep                 Gitleaks                Trivy FS
   (SAST)              (Secret Scan)          (Filesystem Scan)
      │                       │                        │
      └───────────────────────┼────────────────────────┘
                              │
                              ▼
                     Build Docker Image
                              │
                              ▼
                     Trivy Image Scan
                              │
                              ▼
                     Push Image to GHCR
                              │
                              ▼
                  Cosign Keyless Signing
                              │
                              ▼
                 Verify Image Signature
                              │
                              ▼
             Generate Supply Chain Attestation
                              │
                              ▼
              Verify Provenance Attestation
                              │
                              ▼
                 Git Repository (Source of Truth)
                              │
                              ▼
                          ArgoCD
                              │
               Drift Detection & Self-Heal
                              │
                              ▼
                    Kubernetes Cluster
```

## Design Decisions

### Cosign Keyless Signing

Container images are signed using Sigstore Cosign with GitHub OIDC.

No long-lived private keys are stored.

Identity is verified using:

- GitHub Actions OIDC
- Fulcio Certificates
- Rekor Transparency Log

---

### Supply Chain Attestation

After signing, Cosign generates a provenance attestation attached to the image.

This provides cryptographically verifiable build metadata.


### GitOps

Deployment is managed by ArgoCD.

Git serves as the single source of truth.

Manual changes inside the cluster are automatically detected and reconciled.

---

## Prerequisites

Install:

- Docker
- kubectl
- Kind
- Git
- cosign

GitHub Repository Requirements:

- GitHub Actions enabled
- GitHub Container Registry enabled

Image Signing

The image is signed using Cosign Keyless.

```
Image
   │
   ▼
Fulcio Certificate
   │
   ▼
Rekor Transparency Log
```

No private signing keys are required.

---

## Signature Verification

The workflow immediately verifies the signature.

Verification includes:

- OIDC issuer
- Workflow identity
- Rekor transparency log

---

## Provenance Attestation

Cosign generates a provenance attestation describing the build.

The attestation is attached to the image stored in GHCR.

---

## Attestation Verification

The generated attestation is verified.

```
Image
   │
   ▼
Attestation
   │
   ▼
Verification
```

---

## Running the Pipeline

Simply push changes to GitHub.

```
git add .

git commit -m "Update"

git push origin main
```

GitHub Actions automatically executes the pipeline.
  

## Verifying Image Signature

```
cosign verify \
ghcr.io/<github-user>/ledger-api@sha256:<digest>
```

---

## Viewing Supply Chain Metadata

```
cosign tree \
ghcr.io/<github-user>/ledger-api@sha256:<digest>
```

Example output:

```
Attestations
└── sha256:...

Signatures
└── sha256:...
```

---

## Verifying Attestation

```
cosign verify-attestation \
--type custom \
ghcr.io/<github-user>/ledger-api@sha256:<digest>
```

---


## Installing and Configuring ArgoCD

ArgoCD is used to implement GitOps by continuously reconciling the Kubernetes cluster with the desired state stored in Git.

### 1. Create the ArgoCD Namespace

```bash
kubectl create namespace argocd
```

---

### 2. Install ArgoCD

```bash
kubectl apply -n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait until all components are running.

```bash
kubectl get pods -n argocd
```

Expected output:

```
NAME                                              READY   STATUS
argocd-application-controller-0                   1/1     Running
argocd-applicationset-controller                  1/1     Running
argocd-dex-server                                 1/1     Running
argocd-notifications-controller                   1/1     Running
argocd-redis                                      1/1     Running
argocd-repo-server                                1/1     Running
argocd-server                                     1/1     Running
```

> **Note**
>
> Since Kyverno enforces non-root execution for all workloads, the `disallow-root-user` policy was updated to exclude the `argocd` namespace. This allows ArgoCD's own system components to be installed while continuing to enforce the policy for application workloads.

---

### 3. Expose the ArgoCD API Server

For local development:

```bash
kubectl port-forward svc/argocd-server \
-n argocd \
8081:443
```

The UI becomes available at:

```
https://localhost:8081
```

---

### 4. Retrieve the Initial Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d
```

Login using:

Username:

```
admin
```

Password:

```
<decoded password>
```

---

### 5. Create the Application

Apply the GitOps Application manifest.

```bash
kubectl apply -f Task-2-Secure-CICD-Pipeline/argocd/application.yaml
```

Verify:

```bash
kubectl get applications -n argocd
```


## ArgoCD Application

The Application points to the deployment manifests stored in Git.

```
Repository
    │
    ▼
Task-1-Deploy-Ledger-API/deploy/
```


## Demonstrating GitOps

After the application synchronizes successfully, the dashboard should display:

```
Status: Synced

Health: Healthy
```

---

## Demonstrating Drift Detection

Modify the running deployment directly inside the cluster.

For example:


<img width="3356" height="965" alt="Screenshot From 2026-07-11 09-48-45" src="https://github.com/user-attachments/assets/bc9c3d45-b4b9-406e-a52a-768aece6e7ff" />


Healthy, Synced, replicas=5.


After this command:
```bash
kubectl scale deployment ledger-api \
--replicas=2 \
-n payments
```


<img width="3356" height="965" alt="Screenshot From 2026-07-11 09-54-58" src="https://github.com/user-attachments/assets/e3b9c2d9-f762-4a16-8831-317f4e015d78" />



Refresh the ArgoCD UI.


The application will transition to:

```
OutOfSync
```


because the live cluster no longer matches the desired state stored in Git.

---

## Demonstrating Self-Healing

Enable Auto Sync (already configured in the Application).

Within a few seconds ArgoCD reconciles the cluster automatically.


<img width="3356" height="965" alt="Screenshot From 2026-07-11 09-42-48" src="https://github.com/user-attachments/assets/908e95e9-5bb1-4c11-bd25-0b773d80a6d0" />



The deployment is restored to:

```
Replicas = 5
```


The application status returns to:


<img width="3356" height="965" alt="Screenshot From 2026-07-11 09-54-58" src="https://github.com/user-attachments/assets/95bc80d5-2845-4f5e-bc89-5e4d1ea766f1" />



```
Synced
Healthy
```

No manual Kubernetes intervention is required.

---

## Demonstrating Git as the Source of Truth

Modify the deployment manifest in Git.

Example:


<img width="3343" height="993" alt="Screenshot From 2026-07-11 10-01-17" src="https://github.com/user-attachments/assets/248dfaab-cacf-440e-9938-3203c23f7a84" />



Commit and push the change.

```bash
git add .

git commit -m "Scale Ledger API"

git push origin main
```


Pipeline run link:
https://github.com/stormshadow47/dodo-devsecops-assignment/actions/runs/29139708256


ArgoCD detects the new commit and synchronizes the cluster.

The deployment is updated automatically.

This demonstrates that **Git is the single source of truth**, and all desired state changes are performed through version-controlled manifests rather than direct cluster modifications.
