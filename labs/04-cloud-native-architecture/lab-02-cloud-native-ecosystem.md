# Lab 02: Cloud Native Ecosystem

## Objectives
By the end of this lab, you will be able to:
- Understand the CNCF landscape and project maturity levels
- Explore key CNCF projects and their purposes
- Apply cloud-native principles in practice
- Implement 12-factor app methodology
- Understand cloud-native architecture patterns
- Evaluate and choose appropriate cloud-native tools

## Prerequisites
- Running Kubernetes cluster
- kubectl configured and working
- Basic understanding of cloud-native concepts
- Internet access for exploring CNCF landscape

## Estimated Time
90 minutes

---

## Part 1: Understanding the CNCF

### Exercise 1.1: CNCF Overview

**Cloud Native Computing Foundation (CNCF):**
- Part of the Linux Foundation
- Hosts cloud-native open source projects
- Provides vendor-neutral governance
- Fosters collaboration and innovation

**CNCF Project Maturity Levels:**
1. **Sandbox**: Early stage projects
2. **Incubating**: Growing adoption, used in production
3. **Graduated**: Mature, production-ready, widely adopted

**Visit CNCF Landscape:**
```bash
# Open browser
# https://landscape.cncf.io/

# Explore categories:
# - App Definition & Development
# - Orchestration & Management
# - Runtime
# - Provisioning
# - Observability & Analysis
# - Security & Compliance
```

### Exercise 1.2: Key CNCF Projects

**Graduated Projects (Examples):**
- **Kubernetes**: Container orchestration
- **Prometheus**: Monitoring and alerting
- **Envoy**: Service proxy
- **containerd**: Container runtime
- **CoreDNS**: DNS server
- **Helm**: Package manager
- **Harbor**: Container registry
- **Fluentd**: Log aggregation
- **Jaeger**: Distributed tracing
- **Vitess**: Database clustering

**Explore project information:**

```bash
# Clone CNCF project repository for reference
git clone https://github.com/cncf/landscape.git
cd landscape

# View landscape data
cat landscape.yml | grep -A 5 "name: Kubernetes"
```

**Questions:**
1. What criteria must a project meet to graduate?
2. Why is vendor-neutral governance important?
3. How does CNCF differ from other foundations?

---

## Part 2: Core Cloud Native Principles

### Exercise 2.1: Understanding Cloud Native Definition

**CNCF Cloud Native Definition:**
"Cloud native technologies empower organizations to build and run scalable applications in modern, dynamic environments such as public, private, and hybrid clouds. Containers, service meshes, microservices, immutable infrastructure, and declarative APIs exemplify this approach."

**Key Characteristics:**
1. **Containerized**: Packaged in containers
2. **Dynamically Orchestrated**: Actively scheduled and managed
3. **Microservices-Oriented**: Loosely coupled services
4. **Declarative**: Desired state declared, system converges

### Exercise 2.2: Cloud Native vs Traditional

**Create comparison example:**

```yaml
# traditional-deployment.yaml (Anti-pattern)
apiVersion: v1
kind: Pod
metadata:
  name: traditional-app
spec:
  containers:
  - name: monolith
    image: monolithic-app:latest  # Issues: 'latest' tag, monolith
    ports:
    - containerPort: 8080
    env:
    - name: DATABASE_URL
      value: "mysql://hardcoded-db-server:3306/db"  # Hardcoded
    - name: API_KEY
      value: "secret-key-in-plain-text"  # Security issue
    resources: {}  # No resource limits
    # No health checks
    # No proper logging
```

**Cloud native version:**

```yaml
# cloud-native-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloud-native-app
  labels:
    app: cloud-native-app
    version: v1.2.3
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: cloud-native-app
  template:
    metadata:
      labels:
        app: cloud-native-app
        version: v1.2.3
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
    spec:
      serviceAccountName: cloud-native-app-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000

      containers:
      - name: app
        image: myregistry/cloud-native-app:v1.2.3  # Specific version
        imagePullPolicy: IfNotPresent

        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: metrics

        env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database.url
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api.key
        - name: LOG_LEVEL
          value: "info"

        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"

        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10

        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5

        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL

        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/cache

      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: cloud-native-app
spec:
  selector:
    app: cloud-native-app
  ports:
  - port: 80
    targetPort: 8080
    name: http
  - port: 9090
    targetPort: 9090
    name: metrics
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloud-native-app-sa
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database.url: "mysql://db-service:3306/appdb"
  feature.flags: |
    {
      "new_ui": true,
      "beta_features": false
    }
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  api.key: "secure-api-key-from-vault"
```

**Deploy and compare:**

```bash
kubectl apply -f cloud-native-deployment.yaml

# Observe cloud-native features
kubectl get all -l app=cloud-native-app
kubectl describe deployment cloud-native-app
```

**Questions:**
1. What makes an application "cloud native"?
2. How does cloud native differ from "running in the cloud"?
3. What are the benefits of cloud-native architecture?

---

## Part 3: The Twelve-Factor App

### Exercise 3.1: Understanding 12-Factor Methodology

**The Twelve Factors:**
1. **Codebase**: One codebase tracked in version control
2. **Dependencies**: Explicitly declare and isolate dependencies
3. **Config**: Store config in the environment
4. **Backing Services**: Treat backing services as attached resources
5. **Build, Release, Run**: Strictly separate build and run stages
6. **Processes**: Execute the app as stateless processes
7. **Port Binding**: Export services via port binding
8. **Concurrency**: Scale out via the process model
9. **Disposability**: Fast startup and graceful shutdown
10. **Dev/Prod Parity**: Keep development and production similar
11. **Logs**: Treat logs as event streams
12. **Admin Processes**: Run admin tasks as one-off processes

### Exercise 3.2: Implementing 12-Factor Principles

**Factor III: Config in Environment**

```yaml
# 12factor-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-env-config
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  CACHE_TTL: "3600"
  MAX_CONNECTIONS: "100"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: twelve-factor-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: twelve-factor
  template:
    metadata:
      labels:
        app: twelve-factor
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "=== Configuration ==="
          echo "Environment: $APP_ENV"
          echo "Log Level: $LOG_LEVEL"
          echo "Cache TTL: $CACHE_TTL"
          echo "Max Connections: $MAX_CONNECTIONS"
          echo "====================="
          sleep 3600
        envFrom:
        - configMapRef:
            name: app-env-config
        env:
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
---
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  password: "secure-password"
```

**Factor VI: Stateless Processes**

```yaml
# 12factor-stateless.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stateless-app
spec:
  replicas: 5  # Can scale without data loss
  selector:
    matchLabels:
      app: stateless
  template:
    metadata:
      labels:
        app: stateless
    spec:
      containers:
      - name: app
        image: nginx:1.25
        ports:
        - containerPort: 80
        # No local state - uses external services for persistence
        env:
        - name: REDIS_URL
          value: "redis://redis-service:6379"
        - name: DB_URL
          value: "postgresql://postgres-service:5432/db"
```

**Factor VIII: Concurrency**

```yaml
# 12factor-concurrency.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker-app
spec:
  replicas: 3  # Horizontal scaling
  selector:
    matchLabels:
      app: worker
      type: background-job
  template:
    metadata:
      labels:
        app: worker
        type: background-job
    spec:
      containers:
      - name: worker
        image: busybox:1.36
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Worker $HOSTNAME started"
          while true; do
            echo "[$HOSTNAME] Processing job..."
            sleep 10
          done
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: worker-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: worker-app
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Factor IX: Disposability**

```yaml
# 12factor-disposability.yaml
apiVersion: v1
kind: Pod
metadata:
  name: disposable-app
spec:
  terminationGracePeriodSeconds: 30

  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      # Fast startup
      echo "Starting application (fast startup)..."
      sleep 2
      echo "Application ready"

      # Graceful shutdown handler
      cleanup() {
        echo "Received SIGTERM, starting graceful shutdown..."
        echo "Finishing current requests..."
        sleep 3
        echo "Closing connections..."
        sleep 2
        echo "Shutdown complete"
        exit 0
      }

      trap cleanup TERM

      # Main loop
      while true; do
        sleep 5
      done

    readinessProbe:
      exec:
        command: ["true"]
      initialDelaySeconds: 2
      periodSeconds: 5

    livenessProbe:
      exec:
        command: ["true"]
      initialDelaySeconds: 5
      periodSeconds: 10
```

**Factor XI: Logs as Event Streams**

```yaml
# 12factor-logs.yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-stream-app
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      # Application writes to stdout/stderr (not files)
      while true; do
        timestamp=$(date -Iseconds)
        echo "{\"timestamp\":\"$timestamp\",\"level\":\"INFO\",\"message\":\"Processing request\",\"request_id\":\"$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1)\"}"

        # Occasional error to stderr
        if [ $((RANDOM % 20)) -eq 0 ]; then
          echo "{\"timestamp\":\"$timestamp\",\"level\":\"ERROR\",\"message\":\"Processing failed\"}" >&2
        fi

        sleep 2
      done
  # Note: No volume mounts for logs - goes to stdout/stderr
  # Log aggregation system (like Fluentd) collects from stdout
```

**Deploy 12-factor examples:**

```bash
kubectl apply -f 12factor-config.yaml
kubectl apply -f 12factor-stateless.yaml
kubectl apply -f 12factor-concurrency.yaml
kubectl apply -f 12factor-disposability.yaml
kubectl apply -f 12factor-logs.yaml

# Verify
kubectl get pods -l app=twelve-factor
kubectl logs -l app=worker -f
kubectl logs log-stream-app -f
```

**Questions:**
1. Why is storing config in environment variables better than files?
2. How does statelessness enable horizontal scaling?
3. What does "disposability" mean for applications?

---

## Part 4: Cloud Native Patterns

### Exercise 4.1: Sidecar Pattern (Already covered but recap)

**Use cases:**
- Log aggregation
- Monitoring agents
- Service mesh proxies (Envoy)
- Configuration synchronization

### Exercise 4.2: Ambassador Pattern

**Use case: Database proxy**

```yaml
# ambassador-pattern.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-ambassador
spec:
  containers:
  # Main application
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      while true; do
        echo "Connecting to database via localhost:5432 (ambassador)"
        nc -zv localhost 5432
        sleep 10
      done

  # Ambassador proxy
  - name: db-proxy
    image: haproxy:2.8-alpine
    ports:
    - containerPort: 5432
    volumeMounts:
    - name: proxy-config
      mountPath: /usr/local/etc/haproxy

  volumes:
  - name: proxy-config
    configMap:
      name: db-proxy-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-proxy-config
data:
  haproxy.cfg: |
    global
      maxconn 256

    defaults
      mode tcp
      timeout connect 5000ms
      timeout client 50000ms
      timeout server 50000ms

    frontend db_frontend
      bind *:5432
      default_backend db_backend

    backend db_backend
      server db1 postgres-service:5432 check
```

### Exercise 4.3: Circuit Breaker Pattern (Conceptual)

**Purpose:** Prevent cascading failures

```yaml
# circuit-breaker-concept.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: circuit-breaker-demo
data:
  app.sh: |
    #!/bin/sh
    # Simulated circuit breaker

    FAILURE_THRESHOLD=5
    FAILURES=0
    STATE="CLOSED"  # CLOSED, OPEN, HALF_OPEN

    call_service() {
      if [ "$STATE" = "OPEN" ]; then
        echo "Circuit OPEN - failing fast"
        return 1
      fi

      # Simulate service call
      if [ $((RANDOM % 3)) -eq 0 ]; then
        echo "Service call FAILED"
        FAILURES=$((FAILURES + 1))

        if [ $FAILURES -ge $FAILURE_THRESHOLD ]; then
          echo "Opening circuit breaker"
          STATE="OPEN"
        fi
        return 1
      else
        echo "Service call SUCCESS"
        FAILURES=0
        return 0
      fi
    }

    while true; do
      call_service
      sleep 2

      # Attempt to close after timeout
      if [ "$STATE" = "OPEN" ]; then
        sleep 10
        echo "Attempting to close circuit (HALF_OPEN)"
        STATE="HALF_OPEN"
        if call_service; then
          STATE="CLOSED"
          echo "Circuit CLOSED"
        fi
      fi
    done
---
apiVersion: v1
kind: Pod
metadata:
  name: circuit-breaker-demo
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "/scripts/app.sh"]
    volumeMounts:
    - name: scripts
      mountPath: /scripts
  volumes:
  - name: scripts
    configMap:
      name: circuit-breaker-demo
      defaultMode: 0755
```

**Deploy and observe:**

```bash
kubectl apply -f circuit-breaker-concept.yaml
kubectl logs circuit-breaker-demo -f
```

### Exercise 4.4: Service Mesh Concepts

**Service Mesh benefits:**
- Traffic management
- Security (mTLS)
- Observability
- Resilience (retries, circuit breakers)

**Popular service meshes:**
- Istio
- Linkerd
- Consul Connect
- AWS App Mesh

**Conceptual example (Istio-like):**

```yaml
# service-mesh-concept.yaml
# This would be applied in a service mesh environment
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: app-routing
spec:
  hosts:
  - app-service
  http:
  - match:
    - headers:
        user-type:
          exact: beta
    route:
    - destination:
        host: app-service
        subset: v2
      weight: 100
  - route:
    - destination:
        host: app-service
        subset: v1
      weight: 90
    - destination:
        host: app-service
        subset: v2
      weight: 10
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: app-circuit-breaker
spec:
  host: app-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 2
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
```

**Questions:**
1. When should you use the ambassador pattern?
2. What problem does the circuit breaker pattern solve?
3. What are the trade-offs of using a service mesh?

---

## Part 5: Exploring CNCF Projects

### Exercise 5.1: Container Runtime Projects

**containerd:**
```bash
# View containerd info (on node)
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'

# containerd is the industry-standard container runtime
# Used by: Kubernetes, Docker Desktop, AWS EKS, GKE, AKS
```

**CRI-O:**
```bash
# Alternative container runtime focused on Kubernetes
# Lightweight, optimized for Kubernetes CRI
```

### Exercise 5.2: Observability Projects

**Projects overview:**

```yaml
# observability-stack.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: observability
---
# Prometheus - Metrics
# Already covered in previous lab

# Fluentd - Logging
# Collects, processes, and forwards logs

# Jaeger - Distributed Tracing
# Tracks requests across microservices

# Grafana - Visualization
# Dashboard and alerting for all data sources
```

### Exercise 5.3: Security Projects

**Falco - Runtime Security:**

```yaml
# falco-concept.yaml
# Falco detects unexpected application behavior
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-rules
data:
  custom-rules.yaml: |
    - rule: Unauthorized Process in Container
      desc: Detect processes not in approved list
      condition: >
        spawned_process and container and
        not proc.name in (approved_processes)
      output: >
        Unauthorized process started
        (user=%user.name command=%proc.cmdline container=%container.name)
      priority: WARNING

    - rule: Write to Non-temp Directory
      desc: Detect writes outside /tmp
      condition: >
        open_write and container and
        not fd.directory in (/tmp, /var/tmp)
      output: >
        Write to protected directory
        (file=%fd.name container=%container.name)
      priority: WARNING
```

**Open Policy Agent (OPA):**

```yaml
# opa-policy.yaml
# Policy-based control for Kubernetes
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-policy
data:
  policy.rego: |
    package kubernetes.admission

    deny[msg] {
      input.request.kind.kind == "Pod"
      image := input.request.object.spec.containers[_].image
      endswith(image, ":latest")
      msg := "Images must not use 'latest' tag"
    }

    deny[msg] {
      input.request.kind.kind == "Pod"
      not input.request.object.spec.securityContext.runAsNonRoot
      msg := "Pods must run as non-root user"
    }
```

### Exercise 5.4: Storage Projects

**Rook - Cloud Native Storage:**

```yaml
# rook-concept.yaml
# Rook orchestrates Ceph for Kubernetes storage
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
  namespace: rook-ceph
spec:
  dataDirHostPath: /var/lib/rook
  mon:
    count: 3
  storage:
    useAllNodes: true
    useAllDevices: true
```

**Questions:**
1. What CNCF projects would you use for a production cluster?
2. How do you evaluate a CNCF project for adoption?
3. What's the difference between graduated and incubating projects?

---

## Part 6: Building Cloud Native Applications

### Exercise 6.1: Cloud Native Application Checklist

**Checklist:**
- [ ] Containerized
- [ ] Orchestrated (Kubernetes)
- [ ] Microservices architecture
- [ ] API-driven
- [ ] Stateless (where possible)
- [ ] Configuration externalized
- [ ] Health checks implemented
- [ ] Observability (metrics, logs, traces)
- [ ] Security best practices
- [ ] Automated CI/CD
- [ ] Horizontal scaling capability
- [ ] Graceful startup/shutdown
- [ ] Resource limits defined
- [ ] Service mesh ready (optional)

### Exercise 6.2: Migration Strategy

**Strangler Fig Pattern:**

```yaml
# strangler-pattern.yaml
# Gradually migrate from monolith to microservices
apiVersion: v1
kind: Service
metadata:
  name: legacy-app
spec:
  selector:
    app: monolith
  ports:
  - port: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: strangler-ingress
spec:
  rules:
  - http:
      paths:
      # New microservice
      - path: /api/v2/users
        pathType: Prefix
        backend:
          service:
            name: users-microservice
            port:
              number: 80
      # Legacy monolith (catch-all)
      - path: /
        pathType: Prefix
        backend:
          service:
            name: legacy-app
            port:
              number: 80
```

---

## Verification Questions

1. **CNCF:**
   - What is the purpose of CNCF?
   - Name five graduated CNCF projects
   - How does CNCF project governance work?

2. **Cloud Native:**
   - What makes an application "cloud native"?
   - What are the key characteristics?
   - How is it different from traditional architecture?

3. **12-Factor App:**
   - Why externalize configuration?
   - What does "processes as stateless" mean?
   - How should logs be handled?

4. **Patterns:**
   - When would you use a sidecar pattern?
   - What problem does circuit breaker solve?
   - What are benefits of service mesh?

5. **Ecosystem:**
   - How do you choose the right CNCF project?
   - What projects are essential for production?
   - How do projects integrate with each other?

---

## Cleanup

```bash
# Delete all resources
kubectl delete deployment twelve-factor-app stateless-app worker-app
kubectl delete pod app-with-ambassador circuit-breaker-demo disposable-app log-stream-app
kubectl delete configmap app-env-config db-proxy-config circuit-breaker-demo
kubectl delete secret db-credentials
kubectl delete hpa worker-hpa
```

---

## Challenge Exercise

Design and document a complete cloud-native application:

1. **Architecture:**
   - Microservices-based
   - Event-driven communication
   - Use appropriate CNCF projects

2. **Components:**
   - API Gateway
   - 3-5 microservices
   - Message queue
   - Database per service
   - Caching layer

3. **Cloud Native Features:**
   - All 12-factor principles applied
   - Health checks and observability
   - Security best practices
   - Scalability and resilience patterns

4. **Technology Stack:**
   - Choose CNCF projects for each need
   - Justify your choices
   - Document integration points

5. **Deployment:**
   - Kubernetes manifests
   - Helm charts
   - CI/CD pipeline design

**Deliverables:**
- Architecture diagram
- Technology decisions document
- Kubernetes manifests
- README with deployment instructions
- Presentation of design choices

---

## Additional Resources

- [CNCF Landscape](https://landscape.cncf.io/)
- [The Twelve-Factor App](https://12factor.net/)
- [Cloud Native Patterns](https://www.manning.com/books/cloud-native-patterns)
- [CNCF Projects](https://www.cncf.io/projects/)
- [Kubernetes Patterns](https://www.redhat.com/en/resources/oreilly-kubernetes-patterns-ebook)

---

## Key Takeaways

- CNCF provides vendor-neutral governance for cloud-native projects
- Cloud native is about how applications are built and deployed
- The 12-factor methodology provides clear guidelines
- Choose the right CNCF projects for your needs
- Patterns like sidecar and circuit breaker solve common problems
- Observability, security, and scalability are built-in, not added later
- Migration to cloud native can be gradual (strangler pattern)
- Service mesh adds powerful capabilities but increases complexity
- Always consider operational complexity vs. benefits
