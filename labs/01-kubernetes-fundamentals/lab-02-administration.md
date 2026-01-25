# Lab 02: Kubernetes Administration

## Objectives

- Manage cluster resources with kubectl
- Work with ConfigMaps and Secrets
- Implement RBAC (Role-Based Access Control)
- Manage resource requests and limits

## Prerequisites

- Kubernetes cluster running
- kubectl configured
- Completion of Lab 01

## Exercise 1: kubectl Configuration and Context

### Task 1.1: Manage kubectl Contexts

```bash
# View current context
kubectl config current-context

# View all contexts
kubectl config get-contexts

# View cluster info
kubectl config view

# Switch context (if you have multiple clusters)
kubectl config use-context <context-name>

# Set a namespace for current context
kubectl config set-context --current --namespace=default
```

### Task 1.2: kubectl Output Formats

```bash
# Default output
kubectl get pods

# Wide output (more details)
kubectl get pods -o wide

# YAML output
kubectl get pod nginx-pod -o yaml

# JSON output
kubectl get pod nginx-pod -o json

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

# JSONPath
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
```

## Exercise 2: ConfigMaps

### Task 2.1: Create ConfigMaps

Create `app-config.properties`:

```properties
database_host=mysql.default.svc.cluster.local
database_port=3306
log_level=INFO
max_connections=100
```

```bash
# Create ConfigMap from file
kubectl create configmap app-config --from-file=app-config.properties

# Create ConfigMap from literal values
kubectl create configmap app-settings \
  --from-literal=environment=production \
  --from-literal=debug=false

# View ConfigMaps
kubectl get configmaps
kubectl describe configmap app-config
```

### Task 2.2: Use ConfigMap in Pod

Create `pod-with-configmap.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-config
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo $DATABASE_HOST && cat /etc/config/app-config.properties && sleep 3600"]
    env:
    - name: DATABASE_HOST
      valueFrom:
        configMapKeyRef:
          name: app-settings
          key: environment
    - name: DEBUG
      valueFrom:
        configMapKeyRef:
          name: app-settings
          key: debug
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

```bash
# Create the pod
kubectl apply -f pod-with-configmap.yaml

# Check environment variables
kubectl exec app-with-config -- env | grep DATABASE

# Check mounted config file
kubectl exec app-with-config -- cat /etc/config/app-config.properties

# View logs
kubectl logs app-with-config
```

## Exercise 3: Secrets

### Task 3.1: Create Secrets

```bash
# Create secret from literal values
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=secretpass123

# Create secret from files
echo -n 'admin' > username.txt
echo -n 'secretpass123' > password.txt
kubectl create secret generic db-credentials-file \
  --from-file=username.txt \
  --from-file=password.txt

# View secrets (values are base64 encoded)
kubectl get secrets
kubectl describe secret db-credentials
kubectl get secret db-credentials -o yaml

# Decode secret value
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 --decode
```

### Task 3.2: Use Secrets in Pods

Create `pod-with-secret.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-secret
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo Username: $DB_USERNAME && echo Password: $DB_PASSWORD && sleep 3600"]
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
```

```bash
# Create the pod
kubectl apply -f pod-with-secret.yaml

# Check the pod logs
kubectl logs app-with-secret
```

### Task 3.3: Mount Secrets as Files

Create `pod-with-secret-volume.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-secret-volume
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "cat /etc/secrets/username && cat /etc/secrets/password && sleep 3600"]
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: db-credentials
```

```bash
# Create the pod
kubectl apply -f pod-with-secret-volume.yaml

# View mounted secrets
kubectl exec app-with-secret-volume -- ls /etc/secrets
kubectl exec app-with-secret-volume -- cat /etc/secrets/username
```

## Exercise 4: RBAC (Role-Based Access Control)

### Task 4.1: Create a ServiceAccount

```bash
# Create a namespace for testing
kubectl create namespace rbac-test

# Create a service account
kubectl create serviceaccount app-sa -n rbac-test

# View service accounts
kubectl get serviceaccounts -n rbac-test
kubectl describe serviceaccount app-sa -n rbac-test
```

### Task 4.2: Create a Role

Create `pod-reader-role.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: rbac-test
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

```bash
# Create the role
kubectl apply -f pod-reader-role.yaml

# View roles
kubectl get roles -n rbac-test
kubectl describe role pod-reader -n rbac-test
```

### Task 4.3: Create a RoleBinding

Create `pod-reader-binding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: rbac-test
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: rbac-test
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
# Create the role binding
kubectl apply -f pod-reader-binding.yaml

# View role bindings
kubectl get rolebindings -n rbac-test
kubectl describe rolebinding read-pods -n rbac-test
```

### Task 4.4: Test RBAC

Create `test-rbac-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test-pod
  namespace: rbac-test
spec:
  serviceAccountName: app-sa
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["sleep", "3600"]
```

```bash
# Create the test pod
kubectl apply -f test-rbac-pod.yaml

# Test permissions - should work
kubectl exec -it rbac-test-pod -n rbac-test -- kubectl get pods -n rbac-test

# Test permissions - should fail (no permission to create)
kubectl exec -it rbac-test-pod -n rbac-test -- kubectl run test --image=nginx -n rbac-test
```

### Task 4.5: Create ClusterRole and ClusterRoleBinding

Create `cluster-pod-reader.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods-global
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: rbac-test
roleRef:
  kind: ClusterRole
  name: cluster-pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
# Apply cluster-wide RBAC
kubectl apply -f cluster-pod-reader.yaml

# Test - should now work across all namespaces
kubectl exec -it rbac-test-pod -n rbac-test -- kubectl get pods --all-namespaces
```

## Exercise 5: Resource Management

### Task 5.1: Set Resource Requests and Limits

Create `pod-with-resources.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: demo
    image: nginx
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

```bash
# Create the pod
kubectl apply -f pod-with-resources.yaml

# View resource usage
kubectl top pod resource-demo

# View node resource usage
kubectl top nodes

# Describe the pod to see resources
kubectl describe pod resource-demo | grep -A 5 "Requests"
```

### Task 5.2: LimitRange

Create `limitrange.yaml`:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: rbac-test
spec:
  limits:
  - max:
      cpu: "1"
      memory: "1Gi"
    min:
      cpu: "100m"
      memory: "50Mi"
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "200m"
      memory: "128Mi"
    type: Container
```

```bash
# Apply limit range
kubectl apply -f limitrange.yaml

# View limit ranges
kubectl get limitrange -n rbac-test
kubectl describe limitrange resource-limits -n rbac-test
```

### Task 5.3: ResourceQuota

Create `resourcequota.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: rbac-test
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "10"
    services: "5"
    persistentvolumeclaims: "3"
```

```bash
# Apply resource quota
kubectl apply -f resourcequota.yaml

# View quotas
kubectl get resourcequota -n rbac-test
kubectl describe resourcequota compute-quota -n rbac-test
```

## Exercise 6: Useful kubectl Commands

```bash
# Dry run (test without applying)
kubectl apply -f pod.yaml --dry-run=client

# Generate YAML from kubectl command
kubectl run nginx --image=nginx --dry-run=client -o yaml > nginx-pod.yaml

# Edit a resource
kubectl edit deployment nginx-deployment

# Patch a resource
kubectl patch deployment nginx-deployment -p '{"spec":{"replicas":5}}'
kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.19"}]}}}}}'

# Delete resources
kubectl delete pod nginx-pod
kubectl delete -f pod.yaml
kubectl delete pods --all

# Force delete a pod
kubectl delete pod stuck-pod --force --grace-period=0

# Copy files to/from pod
kubectl cp local-file.txt pod-name:/path/in/container
kubectl cp pod-name:/path/in/container/file.txt ./local-file.txt

# Port forwarding
kubectl port-forward pod-name 8080:80

# Proxy to API server
kubectl proxy --port=8080

# Run temporary pod
kubectl run curl-test --image=curlimages/curl -i --rm --restart=Never -- curl http://service-name
```

## Cleanup

```bash
# Clean up resources
kubectl delete namespace rbac-test
kubectl delete configmap app-config app-settings
kubectl delete secret db-credentials db-credentials-file
kubectl delete pod app-with-config app-with-secret app-with-secret-volume resource-demo
rm username.txt password.txt
```

## Challenge Exercise

Create a complete RBAC setup:

1. Create a namespace "team-a"
2. Create a ServiceAccount "developer"
3. Create a Role that allows:
   - Full access to pods, services, and deployments
   - Read-only access to secrets
4. Create a RoleBinding to bind the role to the ServiceAccount
5. Create a pod using this ServiceAccount and test the permissions

## Verification Checklist

- [ ] Used various kubectl output formats
- [ ] Created and used ConfigMaps
- [ ] Created and used Secrets (as env vars and volumes)
- [ ] Implemented RBAC with Roles and RoleBindings
- [ ] Created ClusterRole and ClusterRoleBinding
- [ ] Set resource requests and limits
- [ ] Applied LimitRange and ResourceQuota
- [ ] Practiced useful kubectl commands

## Additional Resources

- [Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
