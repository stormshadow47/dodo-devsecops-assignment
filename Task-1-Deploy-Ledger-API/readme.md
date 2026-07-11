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

``` bash
./startup.sh
```

The Vault listens on `http://localhost:8081`.

## Tokenize a PAN

``` bash
curl -X POST http://127.0.0.1:8092/v1/tokens/tokenize \
  -H "Authorization: Bearer $VAULT_AUTH_KEY" \
  -H "Content-Type: application/json" \
  -d '{"pan":"xxxxxxxxxxxx4422"}'
```


<img width="1389" height="115" alt="Screenshot From 2026-07-11 17-41-30" src="https://github.com/user-attachments/assets/217b82e3-68c6-437d-b555-7b9cef234a6f" />





Example response:

``` json
{"token":"tok_3d9f4d9c1b4e7a21"}
```

## Send the Token to the Ledger API

Replace `<YOUR_LEDGER_ENDPOINT>` with your application's endpoint.

``` bash
curl -k -X POST https://<YOUR_LEDGER_ENDPOINT>/transactions   -H "Content-Type: application/json"   -d '{
    "token":"tok_477bba133c182267",
    "last4":"4242",
    "amount":1999,
    "currency":"USD",
    "status":"authorized"
  }'
```

<img width="1446" height="159" alt="Screenshot From 2026-07-11 17-53-04" src="https://github.com/user-attachments/assets/93877285-faf5-401a-890b-70e73303fd20" />




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


