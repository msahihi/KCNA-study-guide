# Lab 02: Application Debugging and Health Checks

## Objectives
By the end of this lab, you will be able to:
- Debug application-level issues in Kubernetes
- Configure and use liveness, readiness, and startup probes
- Implement proper logging strategies
- Use debugging tools for application troubleshooting
- Monitor application health and behavior
- Apply best practices for observability

## Prerequisites
- Running Kubernetes cluster
- kubectl configured and working
- Completed troubleshooting lab
- Basic understanding of application debugging

## Estimated Time
90 minutes

---

## Part 1: Health Checks Overview

### Exercise 1.1: Understanding Probe Types

**Probe types:**
- **Liveness Probe**: Detects if container is alive (restart if fails)
- **Readiness Probe**: Detects if container is ready to accept traffic
- **Startup Probe**: Detects if application has started (for slow-starting apps)

**Probe mechanisms:**
- HTTP GET
- TCP Socket
- Exec command
- gRPC

### Exercise 1.2: Liveness Probe

**Create pod with HTTP liveness probe:**

```yaml
# liveness-http.yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-http
spec:
  containers:
  - name: app
    image: nginx:1.25
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /
        port: 80
        httpHeaders:
        - name: Custom-Header
          value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3
      timeoutSeconds: 1
      successThreshold: 1
      failureThreshold: 3
```

**Deploy and test:**

```bash
kubectl apply -f liveness-http.yaml

# Watch pod status
kubectl get pod liveness-http -w

# Check events
kubectl describe pod liveness-http

# Simulate failure (make liveness probe fail)
kubectl exec liveness-http -- rm /usr/share/nginx/html/index.html

# Watch pod restart due to failed liveness probe
kubectl get pod liveness-http -w
```

**Create pod with exec liveness probe:**

```yaml
# liveness-exec.yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-exec
spec:
  containers:
  - name: app
    image: busybox:1.36
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

**Deploy and watch:**

```bash
kubectl apply -f liveness-exec.yaml

# Watch pod - will restart after 30 seconds when file is deleted
kubectl get pod liveness-exec -w

# Check restart count
kubectl get pod liveness-exec
```

### Exercise 1.3: Readiness Probe

**Create deployment with readiness probe:**

```yaml
# readiness-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: readiness-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: readiness
  template:
    metadata:
      labels:
        app: readiness
    spec:
      containers:
      - name: app
        image: nginx:1.25
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: readiness-service
spec:
  selector:
    app: readiness
  ports:
  - port: 80
    targetPort: 80
```

**Deploy and test:**

```bash
kubectl apply -f readiness-deployment.yaml

# Check pod ready status
kubectl get pods -l app=readiness

# Check service endpoints (only ready pods)
kubectl get endpoints readiness-service

# Make a pod not ready
POD_NAME=$(kubectl get pod -l app=readiness -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- rm /usr/share/nginx/html/index.html

# Watch pod become not ready
kubectl get pod $POD_NAME -w

# Check endpoints (pod removed)
kubectl get endpoints readiness-service

# Restore readiness
kubectl exec $POD_NAME -- sh -c 'echo "restored" > /usr/share/nginx/html/index.html'
```

### Exercise 1.4: Startup Probe

**Create pod with slow startup:**

```yaml
# startup-probe.yaml
apiVersion: v1
kind: Pod
metadata:
  name: startup-probe
spec:
  containers:
  - name: app
    image: nginx:1.25
    ports:
    - containerPort: 80
    startupProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 0
      periodSeconds: 5
      failureThreshold: 30  # Allow up to 150 seconds for startup
    livenessProbe:
      httpGet:
        path: /
        port: 80
      periodSeconds: 10
      timeoutSeconds: 1
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /
        port: 80
      periodSeconds: 5
```

**Deploy and monitor:**

```bash
kubectl apply -f startup-probe.yaml

# Watch startup
kubectl get pod startup-probe -w

# Describe to see probe transitions
kubectl describe pod startup-probe
```

**Questions:**
1. What happens if both liveness and readiness probes fail?
2. When should you use startup probe instead of increasing liveness initialDelaySeconds?
3. How do probes affect zero-downtime deployments?

---

## Part 2: Application-Level Debugging

### Exercise 2.1: Debug Application with Incorrect Configuration

**Create buggy application:**

```yaml
# buggy-app.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  config.yaml: |
    server:
      port: 8080
    database:
      host: postgres.default.svc.cluster.local
      port: 5432
      name: mydb
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: buggy-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: buggy
  template:
    metadata:
      labels:
        app: buggy
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Starting application..."
          cat /config/config.yaml
          echo "Reading database configuration..."
          DB_HOST=$(grep "host:" /config/config.yaml | awk '{print $2}')
          echo "Connecting to $DB_HOST..."
          # This will fail - no postgres
          nc -zv $DB_HOST 5432 || exit 1
          echo "Application started successfully"
          sleep 3600
        volumeMounts:
        - name: config
          mountPath: /config
        livenessProbe:
          exec:
            command:
            - sh
            - -c
            - "ps | grep sleep"
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: config
        configMap:
          name: app-config
```

**Debug the application:**

```bash
kubectl apply -f buggy-app.yaml

# Check pod status
kubectl get pods -l app=buggy

# View logs
kubectl logs -l app=buggy

# Describe pod for events
kubectl describe pod -l app=buggy

# Check configuration
kubectl exec deployment/buggy-app -- cat /config/config.yaml

# Test network connectivity
kubectl exec deployment/buggy-app -- nc -zv postgres.default.svc.cluster.local 5432 || echo "Connection failed"

# Check if service exists
kubectl get svc postgres

# Debug further with interactive shell
kubectl exec -it deployment/buggy-app -- sh
# Inside: env, ps, netstat, etc.
```

### Exercise 2.2: Debug with Verbose Logging

**Create application with log levels:**

```yaml
# verbose-logging-app.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logging-config
data:
  log-config.sh: |
    #!/bin/sh
    log() {
      local level=$1
      shift
      local message="$@"
      echo "[$(date -Iseconds)] [$level] $message"
    }

    log_debug() { [ "$LOG_LEVEL" = "DEBUG" ] && log "DEBUG" "$@"; }
    log_info() { log "INFO" "$@"; }
    log_warn() { log "WARN" "$@"; }
    log_error() { log "ERROR" "$@"; }
---
apiVersion: v1
kind: Pod
metadata:
  name: verbose-app
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      . /scripts/log-config.sh
      log_info "Application starting..."
      log_debug "Debug: Checking environment variables"
      log_debug "Debug: LOG_LEVEL=$LOG_LEVEL"
      log_debug "Debug: APP_ENV=$APP_ENV"

      log_info "Initializing components..."
      sleep 2

      log_info "Starting main loop..."
      while true; do
        log_debug "Debug: Processing request"
        log_info "Processing completed"
        sleep 10
      done
    env:
    - name: LOG_LEVEL
      value: "DEBUG"  # Change to INFO to reduce logs
    - name: APP_ENV
      value: "development"
    volumeMounts:
    - name: scripts
      mountPath: /scripts
  volumes:
  - name: scripts
    configMap:
      name: logging-config
      defaultMode: 0755
```

**Deploy and view logs:**

```bash
kubectl apply -f verbose-logging-app.yaml

# View logs with debug level
kubectl logs verbose-app -f

# Reduce log level
kubectl set env pod/verbose-app LOG_LEVEL=INFO

# View filtered logs
kubectl logs verbose-app --tail=20
```

### Exercise 2.3: Structured Logging (JSON)

**Create application with JSON logging:**

```yaml
# json-logging-app.yaml
apiVersion: v1
kind: Pod
metadata:
  name: json-logging-app
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      log_json() {
        local level=$1
        local message=$2
        local timestamp=$(date -Iseconds)
        echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\",\"pod\":\"$HOSTNAME\"}"
      }

      log_json "INFO" "Application started"

      counter=0
      while true; do
        counter=$((counter + 1))
        log_json "INFO" "Processed request $counter"

        # Simulate occasional errors
        if [ $((counter % 10)) -eq 0 ]; then
          log_json "ERROR" "Failed to process request $counter"
        fi

        sleep 5
      done
```

**Deploy and parse logs:**

```bash
kubectl apply -f json-logging-app.yaml

# View JSON logs
kubectl logs json-logging-app -f

# Parse with jq (if available)
kubectl logs json-logging-app | jq .

# Filter errors only
kubectl logs json-logging-app | jq 'select(.level=="ERROR")'

# Extract specific fields
kubectl logs json-logging-app | jq -r '"\(.timestamp) \(.level) \(.message)"'
```

**Questions:**
1. Why is structured logging (JSON) better than plain text?
2. How do you correlate logs across multiple pods?
3. What information should always be in application logs?

---

## Part 3: Advanced Debugging Techniques

### Exercise 3.1: Debug with Init Containers

**Create pod with debugging init container:**

```yaml
# debug-init-container.yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-init
spec:
  initContainers:
  - name: debug-env
    image: busybox:1.36
    command: ['sh', '-c']
    args:
    - |
      echo "=== Environment Debug Info ==="
      echo "Hostname: $(hostname)"
      echo "DNS Config:"
      cat /etc/resolv.conf
      echo "Network Interfaces:"
      ip addr
      echo "Environment Variables:"
      env | sort
      echo "=== End Debug Info ==="

  - name: check-dependencies
    image: busybox:1.36
    command: ['sh', '-c']
    args:
    - |
      echo "Checking dependencies..."

      # Check DNS
      nslookup kubernetes.default || echo "DNS check failed"

      # Check external connectivity
      nc -zv google.com 80 || echo "External connectivity failed"

      echo "Dependency check complete"

  containers:
  - name: app
    image: nginx:1.25
```

**Deploy and check:**

```bash
kubectl apply -f debug-init-container.yaml

# View init container logs
kubectl logs debug-init -c debug-env
kubectl logs debug-init -c check-dependencies

# Check main container
kubectl logs debug-init -c app
```

### Exercise 3.2: Debug with Ephemeral Containers

**Create minimal pod to debug:**

```yaml
# minimal-app.yaml
apiVersion: v1
kind: Pod
metadata:
  name: minimal-app
spec:
  containers:
  - name: app
    image: gcr.io/distroless/static-debian11
    command: ["sleep", "3600"]
```

**Debug with ephemeral container:**

```bash
kubectl apply -f minimal-app.yaml

# Add ephemeral debug container
kubectl debug minimal-app -it --image=busybox:1.36 --target=app

# Inside debug container:
# ps aux  # See processes from target container
# netstat -tulpn  # Network connections
# ls /proc/1/root  # See filesystem of PID 1

# Or use more feature-rich debug image
kubectl debug minimal-app -it --image=nicolaka/netshoot --target=app
```

### Exercise 3.3: Debug Failed Pod

**Create pod that fails:**

```yaml
# failed-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: failed-pod
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c"]
    args:
    - |
      echo "Starting initialization..."
      sleep 5
      echo "Checking required files..."
      if [ ! -f /data/required-file ]; then
        echo "ERROR: Required file not found!"
        exit 1
      fi
      echo "Application started"
      sleep 3600
```

**Debug:**

```bash
kubectl apply -f failed-pod.yaml

# Check status
kubectl get pod failed-pod

# View logs
kubectl logs failed-pod

# Create debug copy with fixed configuration
kubectl debug failed-pod -it --copy-to=debug-pod --image=busybox:1.36 -- sh

# Inside debug pod, fix the issue:
mkdir -p /data
touch /data/required-file
# Test manually
```

---

## Part 4: Logging Best Practices

### Exercise 4.1: Centralized Logging Pattern

**Create pod with sidecar logging:**

```yaml
# sidecar-logging.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-logging
spec:
  containers:
  # Main application
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      while true; do
        echo "$(date) - Application log entry" >> /var/log/app.log
        echo "$(date) - Access log entry" >> /var/log/access.log
        sleep 5
      done
    volumeMounts:
    - name: logs
      mountPath: /var/log

  # Sidecar for app logs
  - name: app-log-shipper
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - tail -f /var/log/app.log
    volumeMounts:
    - name: logs
      mountPath: /var/log
      readOnly: true

  # Sidecar for access logs
  - name: access-log-shipper
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - tail -f /var/log/access.log
    volumeMounts:
    - name: logs
      mountPath: /var/log
      readOnly: true

  volumes:
  - name: logs
    emptyDir: {}
```

**Deploy and view logs:**

```bash
kubectl apply -f sidecar-logging.yaml

# View different log streams
kubectl logs sidecar-logging -c app-log-shipper -f
kubectl logs sidecar-logging -c access-log-shipper -f

# View all containers' logs
kubectl logs sidecar-logging --all-containers=true -f
```

### Exercise 4.2: Log Rotation and Management

**Create pod with log rotation:**

```yaml
# log-rotation.yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-rotation
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      # Simple log rotation
      log_file="/var/log/app.log"
      max_size=1048576  # 1MB

      while true; do
        echo "$(date -Iseconds) - Log entry $(date +%s%N)" >> $log_file

        # Check file size and rotate
        size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
        if [ $size -gt $max_size ]; then
          echo "Rotating log file..."
          mv $log_file "${log_file}.old"
          echo "$(date -Iseconds) - New log file after rotation" > $log_file
        fi

        sleep 1
      done
    volumeMounts:
    - name: logs
      mountPath: /var/log

  volumes:
  - name: logs
    emptyDir:
      sizeLimit: 100Mi
```

**Deploy and monitor:**

```bash
kubectl apply -f log-rotation.yaml

# Watch logs grow and rotate
kubectl exec log-rotation -- sh -c 'watch -n 1 "ls -lh /var/log/"'

# View current logs
kubectl logs log-rotation -f
```

### Exercise 4.3: Logging Context and Correlation

**Create application with request tracing:**

```yaml
# traced-app.yaml
apiVersion: v1
kind: Pod
metadata:
  name: traced-app
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      generate_trace_id() {
        cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1
      }

      log_with_trace() {
        local trace_id=$1
        local level=$2
        local message=$3
        local timestamp=$(date -Iseconds)
        echo "{\"timestamp\":\"$timestamp\",\"trace_id\":\"$trace_id\",\"level\":\"$level\",\"message\":\"$message\"}"
      }

      while true; do
        trace_id=$(generate_trace_id)

        log_with_trace "$trace_id" "INFO" "Request received"
        sleep 1
        log_with_trace "$trace_id" "DEBUG" "Processing request"
        sleep 1
        log_with_trace "$trace_id" "INFO" "Request completed"

        sleep 5
      done
```

**Deploy and trace:**

```bash
kubectl apply -f traced-app.yaml

# View logs with trace IDs
kubectl logs traced-app -f

# Filter by specific trace ID
TRACE_ID="<some-trace-id>"
kubectl logs traced-app | jq "select(.trace_id==\"$TRACE_ID\")"
```

**Questions:**
1. When should you use sidecar containers for logging?
2. How do you prevent logs from filling up disk space?
3. What's the difference between application logs and audit logs?

---

## Part 5: Health Check Best Practices

### Exercise 5.1: Proper Health Check Implementation

**Create comprehensive health check application:**

```yaml
# health-check-app.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: health-check-script
data:
  health.sh: |
    #!/bin/sh
    # Comprehensive health check

    check_file_exists() {
      [ -f /tmp/healthy ] || return 1
    }

    check_port_listening() {
      nc -z localhost 8080 || return 1
    }

    check_dependencies() {
      # Check if can resolve DNS
      nslookup kubernetes.default > /dev/null 2>&1 || return 1
    }

    # Run all checks
    check_file_exists && \
    check_port_listening && \
    check_dependencies
---
apiVersion: v1
kind: Pod
metadata:
  name: health-check-app
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      # Create health indicator
      touch /tmp/healthy

      # Start simple HTTP server
      while true; do
        echo -e "HTTP/1.1 200 OK\n\nHealthy" | nc -l -p 8080
      done

    startupProbe:
      exec:
        command:
        - sh
        - /scripts/health.sh
      initialDelaySeconds: 0
      periodSeconds: 5
      failureThreshold: 12  # 60 seconds max startup time

    livenessProbe:
      exec:
        command:
        - sh
        - /scripts/health.sh
      initialDelaySeconds: 0
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3

    readinessProbe:
      exec:
        command:
        - sh
        - /scripts/health.sh
      initialDelaySeconds: 0
      periodSeconds: 5
      timeoutSeconds: 3
      successThreshold: 1
      failureThreshold: 2

    volumeMounts:
    - name: scripts
      mountPath: /scripts

  volumes:
  - name: scripts
    configMap:
      name: health-check-script
      defaultMode: 0755
```

**Deploy and test:**

```bash
kubectl apply -f health-check-app.yaml

# Monitor health
kubectl get pod health-check-app -w

# Test health check manually
kubectl exec health-check-app -- sh /scripts/health.sh && echo "Healthy" || echo "Unhealthy"

# Simulate failure
kubectl exec health-check-app -- rm /tmp/healthy

# Watch pod restart
kubectl get pod health-check-app -w
```

### Exercise 5.2: Graceful Shutdown

**Create application with graceful shutdown:**

```yaml
# graceful-shutdown.yaml
apiVersion: v1
kind: Pod
metadata:
  name: graceful-shutdown
spec:
  terminationGracePeriodSeconds: 30
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      # Trap SIGTERM
      cleanup() {
        echo "Received SIGTERM, starting graceful shutdown..."
        echo "Finishing current requests..."
        sleep 5
        echo "Closing connections..."
        sleep 2
        echo "Cleanup complete, exiting"
        exit 0
      }

      trap cleanup TERM

      echo "Application started"
      while true; do
        echo "Processing..."
        sleep 10
      done
```

**Test graceful shutdown:**

```bash
kubectl apply -f graceful-shutdown.yaml

# Watch logs
kubectl logs graceful-shutdown -f &

# Delete pod and observe graceful shutdown
kubectl delete pod graceful-shutdown --grace-period=30

# Check logs to see shutdown sequence
```

---

## Verification Questions

1. **Health Checks:**
   - What's the difference between liveness and readiness probes?
   - When should you use a startup probe?
   - What happens if a liveness probe fails?

2. **Logging:**
   - What are the benefits of structured logging?
   - How do you handle log aggregation in Kubernetes?
   - What should you never log?

3. **Debugging:**
   - When should you use ephemeral containers?
   - How do you debug a pod that won't start?
   - What tools should be in a debug container image?

4. **Best Practices:**
   - How do you implement distributed tracing?
   - What's the proper way to handle application errors?
   - How do you ensure zero-downtime deployments?

---

## Cleanup

```bash
# Delete all pods
kubectl delete pod liveness-http liveness-exec startup-probe verbose-app json-logging-app debug-init minimal-app failed-pod debug-pod sidecar-logging log-rotation traced-app health-check-app graceful-shutdown

# Delete deployments
kubectl delete deployment readiness-app buggy-app

# Delete services
kubectl delete service readiness-service

# Delete configmaps
kubectl delete configmap app-config logging-config health-check-script
```

---

## Challenge Exercise

Create a production-ready application with:

1. **Comprehensive health checks:**
   - Startup probe for slow initialization
   - Liveness probe checking application health
   - Readiness probe checking dependency availability

2. **Advanced logging:**
   - Structured JSON logging
   - Request tracing with correlation IDs
   - Log levels configurable via environment
   - Sidecar for log shipping

3. **Graceful operations:**
   - Graceful startup
   - Graceful shutdown
   - Proper signal handling

4. **Debugging capabilities:**
   - Debug endpoints (when enabled)
   - Health check endpoints
   - Metrics endpoints

5. **Testing:**
   - Simulate failures
   - Test recovery
   - Verify zero-downtime updates

**Deliverables:**
- Application code/container
- Kubernetes manifests
- Health check implementation
- Logging configuration
- Testing procedures
- Documentation

---

## Additional Resources

- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Logging Architecture](https://kubernetes.io/docs/concepts/cluster-administration/logging/)
- [Debug Running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)
- [The Twelve-Factor App - Logs](https://12factor.net/logs)

---

## Key Takeaways

- Liveness probes prevent zombie containers
- Readiness probes ensure traffic only goes to healthy pods
- Startup probes protect slow-starting applications
- Structured logging enables better observability
- Graceful shutdown prevents request failures
- Always include request correlation in logs
- Health checks should verify actual application health, not just process existence
- Log at appropriate levels (DEBUG only in development)
