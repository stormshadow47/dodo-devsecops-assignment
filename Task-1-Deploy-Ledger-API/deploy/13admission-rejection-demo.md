# Admission Policy Rejection Demonstration

This document demonstrates how the security guardrails reject the original insecure Deployment.

## Original Insecure Deployment Issues

The original `deployment.yaml` has the following security violations:

1. **No ServiceAccount** - Uses default SA (excessive permissions)
2. **Plaintext secrets in env vars** - the original manifest embedded application secrets in git
3. **No securityContext** - Runs as root with full capabilities
4. **No resource limits** - Can starve other workloads
5. **No probes** - No health checks
6. **Root filesystem writable** - Allows runtime modifications
7. **No seccomp profile** - Full syscall access

## Applying Kyverno Policies

First, apply the Kyverno policies:

```bash
kubectl apply -f 08-kyverno-policies.yaml
```

## Attempting to Deploy Original Deployment

```bash
kubectl apply -f deployment.yaml
```

### Expected Rejection by Kyverno

**Policy: disallow-root-user**
```
Error from server: error when creating "deployment.yaml": admission webhook "validate.kyverno.svc" denied the request: 

resource Deployment/default/ledger-api was blocked due to the following policies:

disallow-root-user:
  check-runAsNonRoot: validation error: Containers must run as non-root. Rule check-runAsNonRoot failed at path /spec/template/spec/containers/0/securityContext/runAsNonRoot
  check-runAsUser: validation error: Containers must not run as user 0 (root). Rule check-runAsUser failed at path /spec/template/spec/containers/0/securityContext/runAsUser
```

### Expected Rejection by Pod Security Standards

With PSS labels on the namespace:

```bash
kubectl apply -f deployment.yaml
```

**Error:**
```
Error from server (Forbidden): error when creating "deployment.yaml": pods "ledger-api-xxx" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "ledger-api" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "ledger-api" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "ledger-api" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "ledger-api" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
```

## Deploying the Hardened Version

The hardened deployment (`05-deployment-hardened.yaml`) passes all checks:

```bash
kubectl apply -f 05-deployment-hardened.yaml
```

**Success:**
```
deployment.apps/ledger-api created
```

## Verification

Verify the deployment is running with security contexts:

```bash
kubectl get deployment ledger-api -n payments -o yaml | grep -A 20 securityContext
```

**Output:**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

## Summary

The admission policies successfully:
- ✅ Reject containers running as root
- ✅ Reject images with :latest tags
- ✅ Reject unsigned images (when configured)
- ✅ Enforce Pod Security Standards (restricted)
- ✅ Require dedicated ServiceAccounts
- ✅ Prevent plaintext secrets in git

The hardened deployment passes all security checks and is production-ready.
