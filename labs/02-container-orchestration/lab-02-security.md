# Lab 02: Kubernetes Security

## Objectives

By the end of this lab, you will be able to:

- Configure and apply security contexts at pod and container levels
- Implement Pod Security Standards (Restricted, Baseline, Privileged)
- Configure Role-Based Access Control (RBAC)
- Manage sensitive data using Secrets
- Use Network Policies for security isolation
- Apply security best practices for Kubernetes workloads

## Prerequisites

- Running Kubernetes cluster (v1.25+)
- kubectl with admin access
- Basic understanding of Linux permissions and capabilities
- Completed networking lab for Network Policies

## Estimated Time

120 minutes

---

## Part 1: Security Contexts

### Exercise 1.1: Pod-Level Security Context

**Create a pod with security context:**

```yaml
# pod-security-context.yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    supplementalGroups: [4000]
    seccompProfile:
      type: RuntimeDefault

  containers:
  - name: sec-ctx-demo
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
    volumeMounts:
    - name: data-volume
      mountPath: /data/demo

  volumes:
  - name: data-volume
    emptyDir: {}
```

**Deploy and test:**

```bash
kubectl apply -f pod-security-context.yaml

# Check process user
kubectl exec security-context-demo -- id

# Check file ownership
kubectl exec security-context-demo -- ls -la /data/demo

# Create a file and check ownership
kubectl exec security-context-demo -- touch /data/demo/testfile
kubectl exec security-context-demo -- ls -l /data/demo/testfile
```

**Expected output:**

```
uid=1000 gid=3000 groups=2000,4000
```

### Exercise 1.2: Container-Level Security Context

Container-level settings override pod-level settings.

**Create pod with container security context:**

```yaml
# container-security-context.yaml
apiVersion: v1
kind: Pod
metadata:
  name: container-sec-context
spec:
  securityContext:
    runAsUser: 1000
    fsGroup: 2000

  containers:
  - name: container1
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
    securityContext:
      runAsUser: 2000  # Overrides pod-level
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: cache
      mountPath: /cache

  - name: container2
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
    # Uses pod-level settings

  volumes:
  - name: cache
    emptyDir: {}
```

**Deploy and test:**

```bash
kubectl apply -f container-security-context.yaml

# Check different users in each container
kubectl exec container-sec-context -c container1 -- id
kubectl exec container-sec-context -c container2 -- id

# Test read-only filesystem
kubectl exec container-sec-context -c container1 -- touch /tmp/test
# Should fail with "Read-only file system"
```

### Exercise 1.3: Linux Capabilities

**Drop all capabilities and add only what's needed:**

```yaml
# capabilities-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: capabilities-demo
spec:
  containers:
  - name: no-capabilities
    image: nginx:1.25
    ports:
    - containerPort: 8080
    securityContext:
      runAsUser: 1000
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE  # Allow binding to ports < 1024
```

**Deploy and test:**

```bash
kubectl apply -f capabilities-demo.yaml

# Check capabilities
kubectl exec capabilities-demo -- capsh --print
```

**Questions:**

1. What is the difference between runAsUser and fsGroup?
2. Why should you drop all capabilities by default?
3. What does allowPrivilegeEscalation: false prevent?

---

## Part 2: Pod Security Standards

### Exercise 2.1: Understanding Pod Security Standards

Pod Security Standards define three policies:

- **Privileged**: Unrestricted policy
- **Baseline**: Minimally restrictive, prevents known privilege escalations
- **Restricted**: Heavily restricted, follows hardening best practices

**Create namespace with Pod Security Standards:**

```bash
# Privileged namespace (no restrictions)
kubectl create namespace privileged-ns
kubectl label namespace privileged-ns pod-security.kubernetes.io/enforce=privileged

# Baseline namespace
kubectl create namespace baseline-ns
kubectl label namespace baseline-ns pod-security.kubernetes.io/enforce=baseline
kubectl label namespace baseline-ns pod-security.kubernetes.io/audit=baseline
kubectl label namespace baseline-ns pod-security.kubernetes.io/warn=baseline

# Restricted namespace
kubectl create namespace restricted-ns
kubectl label namespace restricted-ns pod-security.kubernetes.io/enforce=restricted
kubectl label namespace restricted-ns pod-security.kubernetes.io/audit=restricted
kubectl label namespace restricted-ns pod-security.kubernetes.io/warn=restricted
```

### Exercise 2.2: Testing Baseline Policy

**Try to create privileged pod in baseline namespace:**

```yaml
# privileged-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
  namespace: baseline-ns
spec:
  containers:
  - name: privileged
    image: nginx:1.25
    securityContext:
      privileged: true  # This will be blocked
```

**Deploy and observe:**

```bash
kubectl apply -f privileged-pod.yaml
# Should be rejected or warned
```

**Create baseline-compliant pod:**

```yaml
# baseline-compliant-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: baseline-pod
  namespace: baseline-ns
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault

  containers:
  - name: nginx
    image: nginx:1.25
    securityContext:
      allowPrivilegeEscalation: false
```

**Deploy:**

```bash
kubectl apply -f baseline-compliant-pod.yaml
# Should succeed
```

### Exercise 2.3: Testing Restricted Policy

**Create restricted-compliant pod:**

```yaml
# restricted-compliant-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
  namespace: restricted-ns
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault

  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 8080
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run

  volumes:
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
```

**Deploy:**

```bash
kubectl apply -f restricted-compliant-pod.yaml
```

**Questions:**

1. What are the key differences between Baseline and Restricted policies?
2. Can you override namespace-level Pod Security Standards?
3. What happens in "warn" mode vs "enforce" mode?

---

## Part 3: RBAC (Role-Based Access Control)

### Exercise 3.1: Create ServiceAccount

**Create a ServiceAccount:**

```yaml
# serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: default
```

**Deploy:**

```bash
kubectl apply -f serviceaccount.yaml

# View ServiceAccount
kubectl get serviceaccount app-service-account -o yaml
```

### Exercise 3.2: Create Role and RoleBinding

**Create a Role with specific permissions:**

```yaml
# role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]  # "" indicates core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

**Create RoleBinding:**

```yaml
# rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Deploy:**

```bash
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml

# Verify RBAC setup
kubectl describe role pod-reader
kubectl describe rolebinding read-pods
```

### Exercise 3.3: Test RBAC Permissions

**Create a pod using the ServiceAccount:**

```yaml
# pod-with-sa.yaml
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test-pod
  namespace: default
spec:
  serviceAccountName: app-service-account
  containers:
  - name: kubectl
    image: bitnami/kubectl:1.28
    command: ["sleep", "3600"]
```

**Deploy and test:**

```bash
kubectl apply -f pod-with-sa.yaml

# Test allowed operations
kubectl exec rbac-test-pod -- kubectl get pods

# Test denied operation (should fail)
kubectl exec rbac-test-pod -- kubectl get deployments
kubectl exec rbac-test-pod -- kubectl delete pod rbac-test-pod
```

### Exercise 3.4: ClusterRole and ClusterRoleBinding

**Create ClusterRole (cluster-wide):**

```yaml
# clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: namespace-reader
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list"]
```

**Create ClusterRoleBinding:**

```yaml
# clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-namespaces-global
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: default
roleRef:
  kind: ClusterRole
  name: namespace-reader
  apiGroup: rbac.authorization.k8s.io
```

**Deploy and test:**

```bash
kubectl apply -f clusterrole.yaml
kubectl apply -f clusterrolebinding.yaml

# Test cluster-wide permissions
kubectl exec rbac-test-pod -- kubectl get namespaces
kubectl exec rbac-test-pod -- kubectl get nodes
```

### Exercise 3.5: Creating Users with Certificates

**Generate user certificate:**

```bash
# Create private key
openssl genrsa -out developer.key 2048

# Create certificate signing request
openssl req -new -key developer.key -out developer.csr -subj "/CN=developer/O=dev-team"

# Create CertificateSigningRequest in Kubernetes
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: developer-csr
spec:
  request: $(cat developer.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

# Approve the CSR
kubectl certificate approve developer-csr

# Get the certificate
kubectl get csr developer-csr -o jsonpath='{.status.certificate}' | base64 -d > developer.crt
```

**Create Role and RoleBinding for user:**

```yaml
# developer-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: default
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "services"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: default
subjects:
- kind: User
  name: developer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
```

**Configure kubectl context:**

```bash
kubectl apply -f developer-role.yaml

# Add user to kubeconfig
kubectl config set-credentials developer \
  --client-certificate=developer.crt \
  --client-key=developer.key

# Create context
kubectl config set-context developer-context \
  --cluster=$(kubectl config current-context | cut -d'-' -f2-) \
  --user=developer \
  --namespace=default

# Test permissions
kubectl --context=developer-context get pods
kubectl --context=developer-context delete pod rbac-test-pod
# Should fail - no delete permission
```

**Questions:**

1. What is the difference between Role and ClusterRole?
2. Can a RoleBinding reference a ClusterRole?
3. How are RBAC rules evaluated when multiple apply?

---

## Part 4: Secrets Management

### Exercise 4.1: Create and Use Generic Secrets

**Create secret from literals:**

```bash
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=S3cr3tP@ssw0rd
```

**Create secret from file:**

```bash
echo -n 'my-app-secret-key' > app.key
kubectl create secret generic app-secret \
  --from-file=api-key=app.key
```

**View secret (base64 encoded):**

```bash
kubectl get secret db-credentials -o yaml
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 -d
```

### Exercise 4.2: Use Secrets in Pods

**Method 1: Environment variables:**

```yaml
# secret-env-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "echo Username: $DB_USER; echo Password: $DB_PASS; sleep 3600"]
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
    - name: DB_PASS
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
```

**Method 2: Volume mounts:**

```yaml
# secret-volume-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "ls -l /etc/secrets; cat /etc/secrets/username; sleep 3600"]
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true

  volumes:
  - name: secret-volume
    secret:
      secretName: db-credentials
```

**Deploy and test:**

```bash
kubectl apply -f secret-env-pod.yaml
kubectl apply -f secret-volume-pod.yaml

# Check environment variables
kubectl logs secret-env-pod

# Check mounted files
kubectl exec secret-volume-pod -- ls /etc/secrets
kubectl exec secret-volume-pod -- cat /etc/secrets/username
```

### Exercise 4.3: TLS Secrets

**Create TLS secret:**

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=example.com/O=example"

# Create TLS secret
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key
```

**Use TLS secret in Ingress:**

```yaml
# tls-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  tls:
  - hosts:
    - example.com
    secretName: tls-secret
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

### Exercise 4.4: Docker Registry Secrets

**Create Docker-registry secret:**

```bash
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=myusername \
  --docker-password=mypassword \
  --docker-email=myemail@example.com
```

**Use in pod:**

```yaml
# private-image-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-image-pod
spec:
  containers:
  - name: app
    image: myregistry/private-app:v1
  imagePullSecrets:
  - name: regcred
```

**Questions:**

1. Are Secrets encrypted at rest by default?
2. What is the maximum size of a Secret?
3. How do Secret updates affect running pods?

---

## Part 5: Network Policies for Security

### Exercise 5.1: Implement Zero-Trust Networking

**Create isolated namespace:**

```bash
kubectl create namespace zero-trust
```

**Deploy application:**

```yaml
# three-tier-app.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: zero-trust
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: zero-trust
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
      tier: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: zero-trust
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
      tier: backend
  template:
    metadata:
      labels:
        app: backend
        tier: backend
    spec:
      containers:
      - name: api
        image: hashicorp/http-echo:1.0
        args: ["-text=backend"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: zero-trust
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
      tier: database
  template:
    metadata:
      labels:
        app: database
        tier: database
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: password
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: zero-trust
spec:
  selector:
    app: backend
  ports:
  - port: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: zero-trust
spec:
  selector:
    app: database
  ports:
  - port: 5432
```

**Apply default deny:**

```yaml
# default-deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: zero-trust
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**Allow only necessary traffic:**

```yaml
# allow-policies.yaml
# Allow frontend to backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-backend
  namespace: zero-trust
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 5678
---
# Allow backend to database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-to-database
  namespace: zero-trust
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
---
# Allow DNS for all
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: zero-trust
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
---
# Allow frontend egress to backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress
  namespace: zero-trust
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5678
---
# Allow backend egress to database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-egress
  namespace: zero-trust
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
```

**Deploy and test:**

```bash
kubectl apply -f three-tier-app.yaml
kubectl apply -f default-deny-all.yaml
kubectl apply -f allow-policies.yaml

# Wait for pods
kubectl wait --for=condition=Ready pod -l app=frontend -n zero-trust --timeout=60s

# Test allowed connection
kubectl exec -n zero-trust deployment/frontend -- curl -m 5 backend:5678

# Test denied connection
kubectl exec -n zero-trust deployment/frontend -- curl -m 5 database:5432
# Should timeout
```

---

## Verification Questions

1. **Security Contexts:**
   - What is the difference between securityContext at pod vs container level?
   - Why should you use seccompProfile?
   - What capabilities should typically be dropped?

2. **Pod Security Standards:**
   - What are the three Pod Security Standard levels?
   - Can you mix enforce, audit, and warn modes?
   - How do you apply Pod Security Standards to a namespace?

3. **RBAC:**
   - What is the principle of least privilege?
   - Can ServiceAccounts be used across namespaces?
   - What is the difference between Role and ClusterRole?

4. **Secrets:**
   - How are Secrets different from ConfigMaps?
   - Should you commit Secrets to git?
   - What are the security limitations of Kubernetes Secrets?

5. **Network Policies:**
   - Are Network Policies allow or deny by default?
   - Can you create egress rules for external IPs?
   - How do you allow DNS in a default-deny setup?

---

## Cleanup

```bash
# Delete security context pods
kubectl delete pod security-context-demo container-sec-context capabilities-demo

# Delete Pod Security Standard namespaces
kubectl delete namespace privileged-ns baseline-ns restricted-ns

# Delete RBAC resources
kubectl delete pod rbac-test-pod pod-with-sa
kubectl delete rolebinding read-pods developer-binding
kubectl delete role pod-reader developer-role
kubectl delete clusterrolebinding read-namespaces-global
kubectl delete clusterrole namespace-reader
kubectl delete serviceaccount app-service-account
kubectl delete csr developer-csr
rm -f developer.key developer.csr developer.crt

# Delete secrets
kubectl delete secret db-credentials app-secret tls-secret regcred
kubectl delete pod secret-env-pod secret-volume-pod
rm -f app.key tls.key tls.crt

# Delete network policy namespace
kubectl delete namespace zero-trust
```

---

## Challenge Exercise

Create a secure multi-tenant application with:

1. **Two tenants in separate namespaces:**
   - tenant-a
   - tenant-b

2. **Security requirements:**
   - Restricted Pod Security Standard for both namespaces
   - ServiceAccounts with minimum RBAC permissions
   - Network Policies allowing only:
     - Intra-namespace communication
     - Egress to shared database in separate namespace
     - DNS resolution
   - All pods must:
     - Run as non-root
     - Use read-only root filesystem
     - Drop all capabilities
     - Have resource limits

3. **Secrets management:**
   - Database credentials stored as Secrets
   - TLS certificates for each tenant
   - Mounted as volumes, not environment variables

4. **Monitoring requirements:**
   - ServiceAccount for monitoring with read-only cluster access
   - Can view pods, services, and nodes across all namespaces
   - Cannot modify any resources

**Deliverables:**

- Namespace configurations with Pod Security Standards
- RBAC manifests (Roles, RoleBindings, ClusterRoles)
- Network Policy manifests
- Sample application deployments
- Test script demonstrating security boundaries
- Documentation of security model

---

## Additional Resources

- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Security Contexts](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/overview/)

---

## Key Takeaways

- Always run containers as non-root users
- Use Pod Security Standards to enforce security policies
- Implement RBAC with least-privilege principle
- Never commit Secrets to version control
- Use Network Policies to implement defense in depth
- Drop all Linux capabilities by default
- Enable read-only root filesystems when possible
- Use seccomp and AppArmor/SELinux for additional security layers
