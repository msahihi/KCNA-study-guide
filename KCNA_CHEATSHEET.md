# KCNA Exam Cheatsheet & Study Guide

> **Quick Reference for Kubernetes and Cloud Native Associate (KCNA) Certification**

## Table of Contents

1. [Kubernetes Fundamentals (44%)](#kubernetes-fundamentals-44)
2. [Container Orchestration (28%)](#container-orchestration-28)
3. [Cloud Native Application Delivery (16%)](#cloud-native-application-delivery-16)
4. [Cloud Native Architecture (12%)](#cloud-native-architecture-12)
5. [Essential kubectl Commands](#essential-kubectl-commands)
6. [Quick Reference Tables](#quick-reference-tables)
7. [Common Patterns & Best Practices](#common-patterns--best-practices)

---

## Kubernetes Fundamentals (44%)

<details>
<summary><strong>Core Concepts</strong></summary>

#### Kubernetes Architecture

**Control Plane Components:**
- **API Server** (`kube-apiserver`): Frontend for Kubernetes control plane
- **etcd**: Key-value store for cluster data
- **Scheduler** (`kube-scheduler`): Assigns pods to nodes
- **Controller Manager** (`kube-controller-manager`): Runs controller processes
- **Cloud Controller Manager**: Integrates with cloud providers

**Node Components:**
- **kubelet**: Agent that runs on each node
- **kube-proxy**: Network proxy on each node
- **Container Runtime**: containerd, CRI-O, Docker (deprecated)

#### Core Objects

**Pod**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
```

**Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
```

**Service Types:**
- **ClusterIP** (default): Internal cluster access
- **NodePort**: Exposes on each node's IP at static port
- **LoadBalancer**: Cloud provider load balancer
- **ExternalName**: Maps to DNS name
- **Headless**: ClusterIP set to None for direct pod access

**Service Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

#### Workload Resources

| Resource | Purpose | Use Case |
|----------|---------|----------|
| **Deployment** | Stateless apps | Web servers, APIs |
| **ReplicaSet** | Maintain pod replicas | Usually via Deployment |
| **StatefulSet** | Stateful apps | Databases, ZooKeeper |
| **DaemonSet** | One pod per node | Logging, monitoring agents |
| **Job** | Run to completion | Batch processing |
| **CronJob** | Scheduled jobs | Backups, reports |

</details>

<details>
<summary><strong>Administration</strong></summary>

#### ConfigMaps
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_url: "postgres://db:5432"
  log_level: "info"
```

**Using ConfigMap:**
```yaml
# As environment variables
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: database_url

# As volume
volumes:
- name: config
  configMap:
    name: app-config
```

#### Secrets
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded
  password: cGFzc3dvcmQ=
```

**Using Secrets:**
```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: password
```

#### RBAC (Role-Based Access Control)

**Role:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

**RoleBinding:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Key Differences:**
- **Role/RoleBinding**: Namespace-scoped
- **ClusterRole/ClusterRoleBinding**: Cluster-wide

#### Resource Management

**Resource Requests & Limits:**
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

**ResourceQuota:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "10"
```

**LimitRange:**
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-limit-range
spec:
  limits:
  - max:
      memory: "1Gi"
    min:
      memory: "50Mi"
    type: Container
```

</details>

<details>
<summary><strong>Scheduling</strong></summary>

#### Node Selector
```yaml
spec:
  nodeSelector:
    disktype: ssd
```

#### Node Affinity
```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
```

#### Pod Affinity/Anti-Affinity
```yaml
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - web
        topologyKey: kubernetes.io/hostname
```

#### Taints and Tolerations

**Taint a node:**
```bash
kubectl taint nodes node1 key=value:NoSchedule
```

**Toleration:**
```yaml
spec:
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
```

**Taint Effects:**
- **NoSchedule**: Don't schedule new pods
- **PreferNoSchedule**: Try not to schedule
- **NoExecute**: Evict existing pods

</details>

<details>
<summary><strong>Containerization</strong></summary>

#### Container Runtimes
- **containerd**: Industry standard, CNCF graduated
- **CRI-O**: Lightweight, OCI-compliant
- **Docker**: Deprecated in K8s 1.24+

#### Multi-Container Patterns

**Sidecar Pattern:**
```yaml
spec:
  containers:
  - name: app
    image: myapp:1.0
  - name: logging
    image: fluentd:latest
```

**Init Container:**
```yaml
spec:
  initContainers:
  - name: init-db
    image: busybox
    command: ['sh', '-c', 'until nc -z db 5432; do sleep 1; done']
  containers:
  - name: app
    image: myapp:1.0
```

#### Image Best Practices
- Use specific tags (avoid `:latest`)
- Use small base images (alpine, distroless)
- Run as non-root user
- Scan images for vulnerabilities
- Multi-stage builds to reduce size

</details>

---

## Container Orchestration (28%)

<details>
<summary><strong>Networking</strong></summary>

#### CNI Plugins
- **Calico**: Network policy support, BGP
- **Flannel**: Simple overlay network
- **Cilium**: eBPF-based, advanced features
- **Weave Net**: Easy to set up

#### Service Types Quick Reference

| Type | Use Case | Access |
|------|----------|--------|
| ClusterIP | Internal only | cluster.local |
| NodePort | External via node | node-ip:30000-32767 |
| LoadBalancer | Cloud LB | External IP |
| ExternalName | DNS mapping | CNAME |

#### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

#### Network Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-frontend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

#### DNS in Kubernetes
- Service: `<service-name>.<namespace>.svc.cluster.local`
- Pod: `<pod-ip>.<namespace>.pod.cluster.local`
- Headless service pod: `<pod-name>.<service-name>.<namespace>.svc.cluster.local`

</details>

<details>
<summary><strong>Security</strong></summary>

#### Security Context
```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

#### Pod Security Standards

| Level | Description |
|-------|-------------|
| **Privileged** | Unrestricted, allows known privilege escalations |
| **Baseline** | Minimally restrictive, prevents known escalations |
| **Restricted** | Heavily restricted, hardened best practices |

#### Security Best Practices
- ✅ Run as non-root
- ✅ Use read-only root filesystem
- ✅ Drop all capabilities, add only required
- ✅ Use RBAC with least privilege
- ✅ Enable Pod Security Admission
- ✅ Scan images for vulnerabilities
- ✅ Use Network Policies
- ✅ Encrypt secrets at rest
- ✅ Rotate secrets regularly

</details>

<details>
<summary><strong>Troubleshooting</strong></summary>

#### Common Pod States

| State | Description | Common Cause |
|-------|-------------|--------------|
| Pending | Waiting to be scheduled | Resource constraints, taints |
| Running | Pod is running | - |
| Succeeded | Completed successfully | Job finished |
| Failed | Container(s) failed | Application error |
| Unknown | Cannot determine state | Node communication issue |

#### Common Error States

**ImagePullBackOff**
- Wrong image name/tag
- No access to private registry
- Image doesn't exist

**CrashLoopBackOff**
- Application error on startup
- Missing configuration
- Health check failures
- Insufficient resources

**Pending**
- Insufficient resources
- Taints without tolerations
- Node selector doesn't match
- PVC not bound

#### Debug Commands
```bash
# View pod details
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Events
kubectl get events --sort-by=.metadata.creationTimestamp

# Execute commands
kubectl exec -it <pod-name> -- /bin/sh

# Debug with ephemeral container (1.23+)
kubectl debug <pod-name> -it --image=busybox

# Port forward
kubectl port-forward <pod-name> 8080:80

# Resource usage
kubectl top nodes
kubectl top pods
```

</details>

<details>
<summary><strong>Storage</strong></summary>

#### Volume Types

| Type | Lifecycle | Use Case |
|------|-----------|----------|
| emptyDir | Pod | Temporary storage, cache |
| hostPath | Node | Node-local data (dev only) |
| configMap | Independent | Configuration files |
| secret | Independent | Sensitive data |
| persistentVolumeClaim | Independent | Persistent data |

#### PersistentVolume & PersistentVolumeClaim

**PV:**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data
```

**PVC:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
```

#### Access Modes
- **ReadWriteOnce (RWO)**: Single node read-write
- **ReadOnlyMany (ROX)**: Multiple nodes read-only
- **ReadWriteMany (RWX)**: Multiple nodes read-write
- **ReadWriteOncePod (RWOP)**: Single pod read-write

#### Reclaim Policies
- **Retain**: Manual reclamation
- **Delete**: Auto-delete storage
- **Recycle**: Deprecated

#### StorageClass
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "3000"
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

</details>

---

## Cloud Native Application Delivery (16%)

<details>
<summary><strong>Deployment Strategies</strong></summary>

#### Rolling Update (Default)
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
```

**Commands:**
```bash
# Update image
kubectl set image deployment/app app=app:v2

# Rollout status
kubectl rollout status deployment/app

# Rollout history
kubectl rollout history deployment/app

# Rollback
kubectl rollout undo deployment/app
```

#### Blue-Green Deployment
1. Deploy new version (green)
2. Switch service selector to green
3. Remove old version (blue)

#### Canary Deployment
1. Deploy small number of new version
2. Monitor metrics
3. Gradually increase new version replicas
4. Complete rollout or rollback

</details>

<details>
<summary><strong>Helm Basics</strong></summary>

```bash
# Add repository
helm repo add stable https://charts.helm.sh/stable

# Search charts
helm search repo nginx

# Install chart
helm install my-release stable/nginx

# List releases
helm list

# Upgrade release
helm upgrade my-release stable/nginx

# Rollback
helm rollback my-release 1

# Uninstall
helm uninstall my-release
```

**Chart Structure:**
```
mychart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── charts/
```

</details>

<details>
<summary><strong>GitOps Principles</strong></summary>

1. **Declarative**: Desired state in Git
2. **Versioned**: Git as single source of truth
3. **Automated**: Auto-deploy from Git
4. **Reconciled**: Continuous sync of actual vs desired

**GitOps Tools:**
- **Flux**: Kubernetes operator
- **Argo CD**: Declarative CD
- **Jenkins X**: Complete CI/CD

</details>

<details>
<summary><strong>Application Debugging</strong></summary>

#### Health Probes

**Liveness Probe:**
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

**Readiness Probe:**
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```

**Startup Probe:**
```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

#### Probe Types
- **httpGet**: HTTP GET request
- **tcpSocket**: TCP connection
- **exec**: Execute command

#### Graceful Shutdown
```yaml
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", "sleep 15"]
```

</details>

---

## Cloud Native Architecture (12%)

<details>
<summary><strong>Cloud Native Definition (CNCF)</strong></summary>



Cloud native technologies empower organizations to build and run **scalable applications** in modern, dynamic environments. Key characteristics:
- **Containerized**
- **Dynamically orchestrated**
- **Microservices oriented**
- **Declarative APIs**

</details>

<details>
<summary><strong>12-Factor App Methodology</strong></summary>

1. **Codebase**: One codebase in version control
2. **Dependencies**: Explicitly declare dependencies
3. **Config**: Store config in environment
4. **Backing Services**: Treat as attached resources
5. **Build, Release, Run**: Strictly separate stages
6. **Processes**: Execute as stateless processes
7. **Port Binding**: Export services via port binding
8. **Concurrency**: Scale out via process model
9. **Disposability**: Fast startup and shutdown
10. **Dev/Prod Parity**: Keep environments similar
11. **Logs**: Treat as event streams
12. **Admin Processes**: Run as one-off processes

</details>

<details>
<summary><strong>Observability - Three Pillars</strong></summary>

#### 1. Metrics
**Types:**
- Counter (only increases)
- Gauge (up/down)
- Histogram (distribution)
- Summary (quantiles)

**Golden Signals:**
- Latency
- Traffic
- Errors
- Saturation

**RED Method:**
- Rate
- Errors
- Duration

**USE Method:**
- Utilization
- Saturation
- Errors

#### 2. Logs
**Best Practices:**
- Use structured logging (JSON)
- Include correlation IDs
- Centralize logs
- Set retention policies

#### 3. Traces
**Components:**
- **Span**: Single operation
- **Trace**: Collection of spans
- **Context**: Propagated metadata

</details>

<details>
<summary><strong>Prometheus Basics</strong></summary>

**PromQL Examples:**
```promql
# CPU usage rate
rate(container_cpu_usage_seconds_total[5m])

# Memory usage percentage
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100

# Request rate
rate(http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

</details>

<details>
<summary><strong>CNCF Landscape - Key Projects</strong></summary>

#### Graduated Projects
- **Kubernetes**: Container orchestration
- **Prometheus**: Monitoring
- **Envoy**: Cloud-native proxy
- **Helm**: Package manager
- **containerd**: Container runtime
- **Fluentd**: Unified logging
- **Jaeger**: Distributed tracing
- **CoreDNS**: DNS server

#### Incubating Projects
- **Argo**: GitOps CD
- **Flux**: GitOps operator
- **Linkerd**: Service mesh
- **Falco**: Runtime security

</details>

<details>
<summary><strong>Service Mesh</strong></summary>

**Capabilities:**
- Traffic management
- Security (mTLS)
- Observability
- Policy enforcement

**Popular Options:**
- **Istio**: Feature-rich
- **Linkerd**: Lightweight
- **Consul**: Service networking

</details>

<details>
<summary><strong>CNCF & Kubernetes Community</strong></summary>

#### Structure
- **TOC**: Technical Oversight Committee
- **SIGs**: Special Interest Groups
- **WGs**: Working Groups

#### Communication Channels
- Kubernetes Slack
- CNCF Slack
- Mailing lists
- GitHub Discussions

#### Events
- **KubeCon + CloudNativeCon**: Flagship event
- **Kubernetes Community Days**: Local events
- **Meetups**: Regular gatherings

#### Contributing
1. Find a project
2. Look for "good first issue"
3. Read contribution guidelines
4. Fork and clone
5. Make changes
6. Submit PR
7. Address reviews

</details>

---

## Essential kubectl Commands

<details>
<summary><strong>Context & Configuration</strong></summary>


```bash
# View contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context>

# Set namespace
kubectl config set-context --current --namespace=<namespace>

# View current context
kubectl config current-context
```

</details>

<details>
<summary><strong>Resource Management</strong></summary>

```bash
# Get resources
kubectl get pods
kubectl get pods -o wide
kubectl get pods --all-namespaces
kubectl get pods -l app=nginx

# Describe resource
kubectl describe pod <pod-name>

# Create/Apply
kubectl apply -f file.yaml
kubectl create -f file.yaml

# Delete
kubectl delete pod <pod-name>
kubectl delete -f file.yaml

# Edit
kubectl edit deployment <name>
```

</details>

<details>
<summary><strong>Debugging</strong></summary>

```bash
# Logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container>
kubectl logs -f <pod-name>
kubectl logs <pod-name> --previous

# Execute
kubectl exec <pod-name> -- command
kubectl exec -it <pod-name> -- /bin/sh

# Port forward
kubectl port-forward <pod-name> 8080:80

# Events
kubectl get events
kubectl get events --sort-by=.metadata.creationTimestamp

# Top
kubectl top nodes
kubectl top pods
```

</details>

<details>
<summary><strong>Deployments</strong></summary>

```bash
# Scale
kubectl scale deployment <name> --replicas=5

# Set image
kubectl set image deployment/<name> container=image:tag

# Rollout
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout restart deployment/<name>
```

</details>

<details>
<summary><strong>Labels & Selectors</strong></summary>

```bash
# Add label
kubectl label pods <pod-name> env=prod

# Update label
kubectl label pods <pod-name> env=staging --overwrite

# Remove label
kubectl label pods <pod-name> env-

# Select by label
kubectl get pods -l env=prod
kubectl get pods -l 'env in (prod,staging)'
kubectl get pods -l env=prod,tier=frontend
```

</details>

<details>
<summary><strong>Output Formats</strong></summary>

```bash
# YAML
kubectl get pod <name> -o yaml

# JSON
kubectl get pod <name> -o json

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# JSONPath
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
```

</details>

<details>
<summary><strong>Dry Run & Generate</strong></summary>

```bash
# Dry run
kubectl apply -f file.yaml --dry-run=client

# Generate YAML
kubectl run nginx --image=nginx --dry-run=client -o yaml
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml
kubectl create service clusterip nginx --tcp=80:80 --dry-run=client -o yaml
```

</details>

---

## Quick Reference Tables

<details>
<summary><strong>Resource Shortnames</strong></summary>


| Full Name | Shortname |
|-----------|-----------|
| pods | po |
| services | svc |
| deployments | deploy |
| replicasets | rs |
| statefulsets | sts |
| daemonsets | ds |
| configmaps | cm |
| secrets | secret |
| namespaces | ns |
| nodes | no |
| persistentvolumes | pv |
| persistentvolumeclaims | pvc |
| storageclasses | sc |
| ingresses | ing |

</details>

<details>
<summary><strong>API Groups</strong></summary>


| Resource | API Group | API Version |
|----------|-----------|-------------|
| Pod, Service | core | v1 |
| Deployment, ReplicaSet | apps | apps/v1 |
| Ingress | networking.k8s.io | networking.k8s.io/v1 |
| Role, RoleBinding | rbac.authorization.k8s.io | rbac.authorization.k8s.io/v1 |
| NetworkPolicy | networking.k8s.io | networking.k8s.io/v1 |
| StorageClass | storage.k8s.io | storage.k8s.io/v1 |

</details>

<details>
<summary><strong>Common Labels</strong></summary>

```yaml
# Recommended labels
metadata:
  labels:
    app.kubernetes.io/name: myapp
    app.kubernetes.io/instance: myapp-prod
    app.kubernetes.io/version: "1.0"
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: myapp
    app.kubernetes.io/managed-by: helm
```

</details>

<details>
<summary><strong>Container Resource Units</strong></summary>


| Resource | Unit | Example |
|----------|------|---------|
| CPU | Millicores | 250m = 0.25 CPU |
| Memory | Bytes | 64Mi, 1Gi |

### Port Ranges
| Type | Range |
|------|-------|
| NodePort | 30000-32767 |
| Well-known ports | 0-1023 |
| Registered ports | 1024-49151 |

</details>

---

## Common Patterns & Best Practices

<details>
<summary><strong>Security Best Practices</strong></summary>


✅ **DO:**
- Run containers as non-root
- Use read-only root filesystem
- Drop all capabilities, add only needed
- Use RBAC with least privilege
- Scan images for vulnerabilities
- Use Network Policies
- Encrypt secrets at rest
- Use Pod Security Standards

❌ **DON'T:**
- Run privileged containers
- Use latest tag in production
- Store secrets in ConfigMaps
- Grant cluster-admin unnecessarily
- Expose unnecessary ports

</details>

<details>
<summary><strong>Resource Management</strong></summary>

- Always set resource requests
- Set limits for memory
- Use ResourceQuotas per namespace
- Use LimitRanges for defaults
- Monitor resource usage

</details>

<details>
<summary><strong>High Availability</strong></summary>

- Use multiple replicas (odd numbers for quorum)
- Use pod anti-affinity for spreading
- Use readiness probes
- Implement graceful shutdown
- Use PodDisruptionBudgets

</details>

<details>
<summary><strong>Monitoring & Logging</strong></summary>

- Implement health checks
- Use structured logging (JSON)
- Include correlation IDs
- Monitor the golden signals
- Set up alerting
- Use distributed tracing

</details>

<details>
<summary><strong>Deployment Best Practices</strong></summary>

- Use Deployments for stateless apps
- Use StatefulSets for stateful apps
- Implement rolling updates
- Always test in staging first
- Have rollback procedures
- Use GitOps for declarative deployments

</details>

<details>
<summary><strong>Networking Best Practices</strong></summary>

- Use Network Policies by default
- Implement least privilege network access
- Use Ingress for external access
- Consider service mesh for complex scenarios
- Use DNS for service discovery

</details>

---

## Additional Resources

<details>
<summary><strong>Official Documentation</strong></summary>

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [CNCF Curriculum](https://github.com/cncf/curriculum)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

</details>

<details>
<summary><strong>Practice</strong></summary>


- [Killercoda](https://killercoda.com/playgrounds)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)

</details>

<details>
<summary><strong>Community</strong></summary>

- [Kubernetes Slack](https://kubernetes.slack.com/)
- [CNCF Slack #kcna-exam-prep](https://cloud-native.slack.com)
- [r/kubernetes](https://reddit.com/r/kubernetes)

</details>

---

*Understanding concepts is more important than memorizing commands.*
