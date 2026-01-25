# Lab 04: Containerization

## Objectives
By the end of this lab, you will be able to:
- Understand container fundamentals and how they differ from virtual machines
- Work with different container runtimes (containerd, CRI-O)
- Build container images using best practices
- Implement multi-container patterns (sidecar, adapter, ambassador)
- Apply security best practices for container images

## Prerequisites
- Access to a Kubernetes cluster (minikube, kind, or cloud provider)
- Docker or Podman installed locally
- kubectl configured to communicate with your cluster
- Basic understanding of Linux and command-line operations

## Estimated Time
90 minutes

---

## Part 1: Container Basics

### Exercise 1.1: Understanding Container Runtimes

**Check your cluster's container runtime:**

```bash
kubectl get nodes -o wide
```

**Inspect node information to see the container runtime:**

```bash
kubectl describe node <node-name> | grep "Container Runtime"
```

**Expected output:**
```
Container Runtime Version:  containerd://1.6.24
```

### Exercise 1.2: Working with containerd

**Access a node and interact with containerd (if using minikube):**

```bash
minikube ssh

# List containers using crictl (CRI tool)
sudo crictl ps

# List images
sudo crictl images

# Inspect a container
sudo crictl inspect <container-id>

# View container logs
sudo crictl logs <container-id>
```

**Questions:**
1. What is the difference between Docker and containerd?
2. Why did Kubernetes deprecate Docker as a container runtime?
3. What is the Container Runtime Interface (CRI)?

---

## Part 2: Building Container Images

### Exercise 2.1: Create a Simple Application

**Create a directory for your application:**

```bash
mkdir -p ~/container-lab
cd ~/container-lab
```

**Create a simple Python application (`app.py`):**

```python
from flask import Flask
import os
import socket

app = Flask(__name__)

@app.route('/')
def hello():
    hostname = socket.gethostname()
    version = os.getenv('APP_VERSION', 'v1.0')
    return f'Hello from {hostname}! Version: {version}\n'

@app.route('/health')
def health():
    return {'status': 'healthy'}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

**Create requirements.txt:**

```txt
flask==3.0.0
```

### Exercise 2.2: Create a Dockerfile with Best Practices

**Create a Dockerfile:**

```dockerfile
# Use specific version tags, not 'latest'
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Install dependencies in a separate layer
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Multi-stage build - final image
FROM python:3.11-slim

# Create non-root user
RUN useradd -m -u 1000 appuser

# Set working directory
WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser app.py .

# Set environment variables
ENV PATH=/home/appuser/.local/bin:$PATH \
    APP_VERSION=v1.0 \
    PYTHONUNBUFFERED=1

# Use non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8080/health')" || exit 1

# Run application
CMD ["python", "app.py"]
```

**Build the image:**

```bash
docker build -t my-app:v1.0 .

# Tag for different versions
docker tag my-app:v1.0 my-app:latest
```

### Exercise 2.3: Image Best Practices

**Create an optimized Dockerfile with .dockerignore:**

**Create `.dockerignore`:**

```
__pycache__
*.pyc
*.pyo
*.pyd
.Python
*.so
pip-log.txt
.env
.git
.gitignore
.dockerignore
Dockerfile
README.md
tests/
*.md
```

**Scan the image for vulnerabilities (if using Docker):**

```bash
docker scan my-app:v1.0
```

**Inspect image layers:**

```bash
docker history my-app:v1.0
```

**Check image size:**

```bash
docker images my-app
```

**Questions:**
1. Why use multi-stage builds?
2. What are the security implications of running containers as root?
3. How does `.dockerignore` help with image optimization?

---

## Part 3: Multi-Container Patterns

### Exercise 3.1: Sidecar Pattern

The sidecar pattern extends and enhances the main container's functionality.

**Create `sidecar-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-example
  labels:
    app: sidecar-demo
spec:
  containers:
  # Main application container
  - name: main-app
    image: nginx:1.25
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx

  # Sidecar container - log aggregator
  - name: log-sidecar
    image: busybox:1.36
    command: ['sh', '-c']
    args:
    - |
      while true; do
        if [ -f /var/log/nginx/access.log ]; then
          tail -f /var/log/nginx/access.log | while read line; do
            echo "[LOG PROCESSOR] $line"
          done
        fi
        sleep 1
      done
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
      readOnly: true

  volumes:
  - name: shared-logs
    emptyDir: {}
```

**Deploy and test:**

```bash
kubectl apply -f sidecar-pod.yaml

# Check both containers are running
kubectl get pod sidecar-example

# Generate some traffic
kubectl exec sidecar-example -c main-app -- curl localhost

# View sidecar logs
kubectl logs sidecar-example -c log-sidecar
```

### Exercise 3.2: Adapter Pattern

The adapter pattern standardizes and normalizes output from the main container.

**Create `adapter-pod.yaml`:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: adapter-script
data:
  adapter.sh: |
    #!/bin/sh
    # Adapter that converts log format
    tail -f /var/log/app/application.log | while read line; do
      timestamp=$(date -Iseconds)
      echo "{\"timestamp\":\"$timestamp\",\"message\":\"$line\",\"level\":\"INFO\"}"
    done
---
apiVersion: v1
kind: Pod
metadata:
  name: adapter-example
spec:
  containers:
  # Main application
  - name: app
    image: busybox:1.36
    command: ['sh', '-c']
    args:
    - |
      mkdir -p /var/log/app
      while true; do
        echo "Application log entry at $(date)" >> /var/log/app/application.log
        sleep 5
      done
    volumeMounts:
    - name: logs
      mountPath: /var/log/app

  # Adapter container - converts log format to JSON
  - name: adapter
    image: busybox:1.36
    command: ['sh', '/scripts/adapter.sh']
    volumeMounts:
    - name: logs
      mountPath: /var/log/app
      readOnly: true
    - name: scripts
      mountPath: /scripts

  volumes:
  - name: logs
    emptyDir: {}
  - name: scripts
    configMap:
      name: adapter-script
      defaultMode: 0755
```

**Deploy and test:**

```bash
kubectl apply -f adapter-pod.yaml

# Wait for pod to be ready
kubectl wait --for=condition=Ready pod/adapter-example --timeout=60s

# View formatted logs from adapter
kubectl logs adapter-example -c adapter -f
```

### Exercise 3.3: Ambassador Pattern

The ambassador pattern proxies connections to external services.

**Create `ambassador-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ambassador-example
spec:
  containers:
  # Main application
  - name: app
    image: curlimages/curl:8.5.0
    command: ['sh', '-c']
    args:
    - |
      while true; do
        echo "Making request through ambassador..."
        curl -s http://localhost:8080/
        sleep 10
      done

  # Ambassador container - proxy to external service
  - name: ambassador
    image: nginx:1.25
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: nginx-config
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf

  volumes:
  - name: nginx-config
    configMap:
      name: ambassador-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ambassador-config
data:
  nginx.conf: |
    events {
      worker_connections 1024;
    }
    http {
      server {
        listen 8080;
        location / {
          proxy_pass http://httpbin.org;
          proxy_set_header Host httpbin.org;
        }
      }
    }
```

**Deploy and test:**

```bash
kubectl apply -f ambassador-pod.yaml

# View logs showing proxied requests
kubectl logs ambassador-example -c app -f
```

**Questions:**
1. When would you use a sidecar pattern instead of adding functionality to the main container?
2. What are the resource implications of multi-container pods?
3. How do containers in the same pod communicate?

---

## Part 4: Init Containers

Init containers run before app containers and are used for setup tasks.

**Create `init-container-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  initContainers:
  # First init container - downloads configuration
  - name: init-download
    image: busybox:1.36
    command: ['sh', '-c']
    args:
    - |
      echo "Downloading configuration..."
      echo "database_url=postgresql://db:5432/myapp" > /config/app.conf
      echo "cache_enabled=true" >> /config/app.conf
      echo "Configuration downloaded successfully"
    volumeMounts:
    - name: config
      mountPath: /config

  # Second init container - waits for dependency
  - name: init-wait
    image: busybox:1.36
    command: ['sh', '-c']
    args:
    - |
      echo "Waiting for database to be ready..."
      until nc -z -v -w30 postgres-service 5432; do
        echo "Waiting for postgres-service..."
        sleep 2
      done
      echo "Database is ready!"

  containers:
  # Main application container
  - name: app
    image: busybox:1.36
    command: ['sh', '-c']
    args:
    - |
      echo "Application starting..."
      cat /config/app.conf
      echo "Running application..."
      tail -f /dev/null
    volumeMounts:
    - name: config
      mountPath: /config
      readOnly: true

  volumes:
  - name: config
    emptyDir: {}
```

**For testing, create a dummy postgres service:**

```yaml
# postgres-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: postgres
---
apiVersion: v1
kind: Pod
metadata:
  name: postgres
  labels:
    app: postgres
spec:
  containers:
  - name: postgres
    image: postgres:16-alpine
    env:
    - name: POSTGRES_PASSWORD
      value: password
    ports:
    - containerPort: 5432
```

**Deploy and test:**

```bash
# Deploy postgres first
kubectl apply -f postgres-service.yaml

# Wait for postgres to be ready
kubectl wait --for=condition=Ready pod/postgres --timeout=120s

# Now deploy the init container example
kubectl apply -f init-container-pod.yaml

# Watch the init containers execute
kubectl get pod init-demo -w

# Check init container logs
kubectl logs init-demo -c init-download
kubectl logs init-demo -c init-wait

# Check main container logs
kubectl logs init-demo -c app
```

---

## Part 5: Container Security Best Practices

### Exercise 5.1: Security Contexts

**Create `secure-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault

  containers:
  - name: secure-container
    image: nginx:1.25
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE

    ports:
    - containerPort: 8080

    volumeMounts:
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
    - name: tmp
      mountPath: /tmp

  volumes:
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
  - name: tmp
    emptyDir: {}
```

**Test security context:**

```bash
kubectl apply -f secure-pod.yaml

# Check if pod is running with correct user
kubectl exec secure-pod -- id

# Try to escalate privileges (should fail)
kubectl exec secure-pod -- whoami
```

### Exercise 5.2: Resource Limits and Requests

**Create `resources-pod.yaml`:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: app
    image: nginx:1.25
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
```

**Deploy and monitor:**

```bash
kubectl apply -f resources-pod.yaml

# Check resource usage
kubectl top pod resource-demo

# View resource configuration
kubectl describe pod resource-demo | grep -A 10 "Limits\|Requests"
```

---

## Verification Questions

Answer these questions to verify your understanding:

1. **Container Runtimes:**
   - What is the difference between containerd and Docker?
   - How does CRI-O differ from containerd?
   - What is the OCI (Open Container Initiative)?

2. **Image Building:**
   - Why should you avoid using the `latest` tag in production?
   - What are the benefits of multi-stage builds?
   - How does layer caching work in Docker builds?

3. **Multi-Container Patterns:**
   - When would you use a sidecar vs. an init container?
   - What are the networking characteristics of containers in the same pod?
   - How do containers in a pod share storage?

4. **Security:**
   - Why is it important to run containers as non-root?
   - What is the purpose of seccomp profiles?
   - How do capabilities work in Linux containers?

---

## Cleanup

```bash
# Delete all resources created in this lab
kubectl delete pod sidecar-example
kubectl delete pod adapter-example
kubectl delete configmap adapter-script
kubectl delete pod ambassador-example
kubectl delete configmap ambassador-config
kubectl delete pod init-demo
kubectl delete pod postgres
kubectl delete service postgres-service
kubectl delete pod secure-pod
kubectl delete pod resource-demo

# Clean up local Docker images
docker rmi my-app:v1.0 my-app:latest
rm -rf ~/container-lab
```

---

## Challenge Exercise

Create a production-ready multi-container pod that implements the following:

1. **Main application container:**
   - Custom Node.js or Python application
   - Runs as non-root user
   - Has resource limits
   - Includes health checks

2. **Init container:**
   - Downloads configuration from a ConfigMap
   - Validates environment variables
   - Creates required directories

3. **Sidecar container:**
   - Collects and formats application logs
   - Exposes metrics on a separate port
   - Uses minimal resources

4. **Security requirements:**
   - Read-only root filesystem
   - No privilege escalation
   - Drop all capabilities except necessary ones
   - Use seccomp profile

**Bonus challenges:**
- Build the image using best practices (multi-stage, minimal layers)
- Scan the image for vulnerabilities
- Implement a custom health check script
- Add resource quotas and limit ranges

**Deliverables:**
- Dockerfile with all best practices applied
- Pod YAML with all three container types
- Documentation of security decisions
- Test script demonstrating all functionality

---

## Additional Resources

- [Container Runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
- [Best Practices for Container Images](https://cloud.google.com/architecture/best-practices-for-building-containers)
- [Multi-Container Pod Patterns](https://kubernetes.io/blog/2015/06/the-distributed-system-toolkit-patterns/)
- [Kubernetes Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [CRI-O Documentation](https://cri-o.io/)
- [containerd Documentation](https://containerd.io/)

---

## Key Takeaways

- Container runtimes (containerd, CRI-O) implement the CRI to work with Kubernetes
- Multi-stage builds reduce image size and improve security
- Multi-container patterns (sidecar, adapter, ambassador) solve specific architectural challenges
- Security contexts enforce least-privilege principles
- Init containers handle setup tasks before main containers start
- Resource limits prevent containers from consuming excessive resources
