# Task 1 -- Deploy & Harden the Ledger API

## Overview

This task hardens the provided Ledger API into a production-ready
Kubernetes deployment by applying security best practices across
workload configuration, secrets management, networking, RBAC, and
admission control. The deployment is fully automated using a single
`setup.sh` script.

## Architecture


<img width="707" height="721" alt="Screenshot From 2026-07-11 11-58-26" src="https://github.com/user-attachments/assets/618784a7-1139-47e8-b1f4-2395c2797b25" />




## Design Decisions

-   Sealed Secrets are used as it works by using asymmetric cryptography. This model is effective when you manage a single cluster controller.
-   Secrets were written as plaintext in the app- decided to tokenize the app before writing to DB and only the last 4digits are revealed, ensuring PCI compliance.
-   A better approach (for scalabiity and security) would be to store secrets in an external secret manager/ESO and a managed DB to store tokenized PAN and transaction metadata, if needed.
-   Deployment Automation: The entire environment is provisioned through a single setup.sh entry point. This script orchestrates cluster creation, image build, TLS generation, workload deployment, and post-deployment validation.
-   ConfigMaps store non-sensitive configuration.
-   Kyverno enforces security guardrails at admission time.
-   Resource requests/limits and health probes improve reliability.

## Repository Structure

``` text
Task-1-Deploy-Ledger-API
├── app/
├── deploy/
├── mock-vault/
├── setup.sh
├── startup.sh
└── README.md
```

## Prerequisites

-   Docker
-   Kind
-   kubectl
-   Python 3
-   Git


## Automated Deployment

The entire deployment is orchestrated through a single entry-point script:

```bash
./setup.sh
```

The script automates the complete environment provisioning, eliminating manual deployment steps and ensuring a repeatable setup.

Once the script completes successfully, the following components are available in the cluster:

## Deployment Components

  Manifest                 Purpose
  ------------------------ --------------------------
  namespace.yaml           Namespace
  serviceaccount.yaml      Least-privilege identity
  rbac.yaml                RBAC
  configmap.yaml           Configuration
  sealedsecret.yaml        Encrypted secrets
  service.yaml             Service
  deployment-ledger.yaml   Hardened workload
  ingress.yaml             External access
  neighbour.yaml           Reporting service
  networkpolicy.yaml       Network isolation
  kyverno-policies.yaml    Admission control

The deployment is fully automated, allowing the environment to be recreated consistently with a single command.

## Check running resources after deploying cluster

```
./deploy/scripts/status.sh
```


## Setup

Clone the repository:

```bash
git clone <repository-url>
cd dodo-devsecops-assignment
```

Run the complete deployment:

```bash
cd Task-1-Deploy-Ledger-API
chmod +x setup.sh
./setup.sh
```

The script provisions the Kubernetes cluster, builds the application and deploys all Kubernetes resources



## Running the mock-vault

``` bash

cd Task-1-Deploy-Ledger-API/mock-vault
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Create `.env.local`:

``` local env:
VAULT_AUTH_KEY=demo-vault-token
```

Load it:

``` bash
set -a
source .env.local
set +a
```

## Running the Mock Vault

``` bash
./startup.sh
```

The Vault listens on `http://localhost:8081`.

## Tokenize a PAN

``` bash
curl -X POST http://localhost:8081/tokenize \
  -H "Authorization: Bearer $VAULT_AUTH_KEY" \
  -H "Content-Type: application/json" \
  -d '{"pan":"4242424242424242"}'
```

Example response:

``` json
{"token":"tok_3d9f4d9c1b4e7a21"}
```

## Send the Token to the Ledger API

Replace `<YOUR_LEDGER_ENDPOINT>` with your application's endpoint.

``` bash
curl -X POST http://localhost:8080/<YOUR_LEDGER_ENDPOINT> \
  -H "Content-Type: application/json" \
  -d '{
    "token":"tok_3d9f4d9c1b4e7a21",
    "metadata":{
      "customer_id":"cust-1001",
      "merchant_id":"merchant-001",
      "order_id":"order-5001",
      "amount":1999,
      "currency":"USD",
      "description":"Demo payment"
    }
  }'
```

The Ledger API receives only a token and business metadata; the original
PAN never reaches the application.




## Security Controls

-   Non-root containers
-   Read-only root filesystem
-   Dropped Linux capabilities
-   RuntimeDefault seccomp
-   Resource requests and limits
-   Liveness/readiness probes
-   ConfigMaps
-   Sealed Secrets
-   Dedicated ServiceAccounts
-   Least-privilege RBAC
-   Network Policies
-   Kyverno admission policies


## Demonsrating the hardened workload:



<img width="1054" height="634" alt="Screenshot From 2026-07-11 13-35-40" src="https://github.com/user-attachments/assets/abb966c9-0c38-4cb4-9bc3-164b4c1539bc" />




## Demonstrating Admission Control

``` bash
kubectl apply -f deployment.yaml
```


<img width="1884" height="835" alt="redated_deployment" src="https://github.com/user-attachments/assets/1f63fb77-b17d-4aec-b9b9-30f35763743f" />



Kyverno rejects the insecure deployment because it violates the enforced
security policies.


```

## Cleanup

``` bash
kind delete cluster
```


