# Security

## Overview

Security best practices, policies, and mechanisms for containerized environments.

## Key Topics

### Security Principles

- Defense in depth
- Least privilege principle
- Zero trust security model
- Security by default

### Pod Security

- **Security Context**: Define privilege and access control settings
- **Pod Security Standards**: Privileged, Baseline, Restricted
- **Pod Security Admission**: Enforce pod security standards
- Running containers as non-root
- Read-only root filesystems
- Dropping unnecessary capabilities

### Authentication and Authorization

- **Authentication**: Verify user identity
  - X.509 certificates
  - Bearer tokens
  - Service accounts
- **Authorization**: Control access to resources
  - RBAC (Role-Based Access Control)
  - ABAC (Attribute-Based Access Control)
  - Webhook mode

### RBAC (Role-Based Access Control)

- Roles and ClusterRoles
- RoleBindings and ClusterRoleBindings
- Service accounts for pods
- Principle of least privilege

### Network Security

- Network policies for pod-to-pod traffic control
- Ingress and egress rules
- Service mesh security (mTLS)
- Network segmentation

### Secrets Management

- Kubernetes Secrets
- Encryption at rest
- External secret management (Vault, AWS Secrets Manager)
- Secret rotation
- Avoiding hardcoded secrets

### Image Security

- Image scanning for vulnerabilities
- Image signing and verification
- Private registries
- Image pull policies
- Admission controllers for image validation

### Runtime Security

- Container runtime security
- AppArmor and SELinux profiles
- Seccomp profiles
- Detecting and preventing runtime threats

## Examples

### Security Context

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    image: myapp:1.0
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

### RBAC Role and RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Using Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded
  password: cGFzc3dvcmQ=  # base64 encoded
---
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
```

## Study Resources

- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

## Key Points to Remember

- Always run containers as non-root when possible
- Use RBAC to control access to cluster resources
- Store sensitive data in Secrets, not ConfigMaps
- Scan images for vulnerabilities regularly
- Apply network policies to restrict traffic
- Use security contexts to limit container privileges
- Enable Pod Security Admission

## Hands-On Practice

- [Lab 02: Security](../../labs/02-container-orchestration/lab-02-security.md) - Practical exercises covering security contexts, Pod Security Standards, RBAC, and Network Policies
