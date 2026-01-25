# Lab 01: Cloud Native Observability

## Objectives

By the end of this lab, you will be able to:

- Understand the three pillars of observability (metrics, logs, traces)
- Configure Prometheus for metrics collection
- Create Grafana dashboards for visualization
- Implement logging strategies with kubectl
- Understand basic distributed tracing concepts
- Apply observability best practices

## Prerequisites

- Running Kubernetes cluster
- kubectl configured and working
- Helm 3 installed
- Basic understanding of monitoring concepts

## Estimated Time

120 minutes

---

## Part 1: Understanding Observability

### Exercise 1.1: Three Pillars of Observability

**The Three Pillars:**

1. **Metrics**: Numerical measurements over time (CPU, memory, request rate)
2. **Logs**: Discrete events with context (errors, warnings, info)
3. **Traces**: Request paths through distributed systems

**Why observability matters:**

- Understand system behavior
- Detect and diagnose issues
- Optimize performance
- Plan capacity
- Meet SLAs/SLOs

---

## Part 2: Metrics with Prometheus

### Exercise 2.1: Install Prometheus Stack

**Install using Helm:**

```bash
# Add Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring

# Install kube-prometheus-stack (includes Prometheus, Grafana, Alertmanager)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin

# Wait for pods to be ready
kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=300s

# Check installation
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### Exercise 2.2: Access Prometheus and Grafana

**Access Prometheus:**

```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Open browser: http://localhost:9090
# Try queries:
# - up
# - rate(container_cpu_usage_seconds_total[5m])
# - sum(rate(container_network_receive_bytes_total[5m])) by (pod)
```

**Access Grafana:**

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &

# Open browser: http://localhost:3000
# Login: admin / admin (or password set during install)
# Explore pre-built dashboards:
# - Kubernetes / Compute Resources / Cluster
# - Kubernetes / Compute Resources / Namespace (Pods)
# - Kubernetes / Networking / Cluster
```

### Exercise 2.3: Create Application with Metrics

**Create application that exposes metrics:**

```yaml
# metrics-app.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: metrics-app-script
data:
  app.sh: |
    #!/bin/sh
    # Simple metrics server
    COUNTER=0
    REQUESTS=0

    while true; do
      REQUESTS=$((REQUESTS + 1))

      # Simulate metrics endpoint
      METRICS="# HELP app_requests_total Total number of requests
    # TYPE app_requests_total counter
    app_requests_total $REQUESTS

    # HELP app_counter_current Current counter value
    # TYPE app_counter_current gauge
    app_counter_current $COUNTER

    # HELP app_processing_seconds Processing time
    # TYPE app_processing_seconds histogram
    app_processing_seconds_bucket{le=\"0.1\"} $((REQUESTS * 8 / 10))
    app_processing_seconds_bucket{le=\"0.5\"} $((REQUESTS * 95 / 100))
    app_processing_seconds_bucket{le=\"1.0\"} $REQUESTS
    app_processing_seconds_sum $((REQUESTS * 30 / 100))
    app_processing_seconds_count $REQUESTS"

      # Serve metrics on port 8080
      echo -e "HTTP/1.1 200 OK\nContent-Type: text/plain\n\n$METRICS" | nc -l -p 8080

      COUNTER=$((COUNTER + 1))
    done
---
apiVersion: v1
kind: Pod
metadata:
  name: metrics-app
  labels:
    app: metrics-app
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "/scripts/app.sh"]
    ports:
    - containerPort: 8080
      name: metrics
    volumeMounts:
    - name: scripts
      mountPath: /scripts
  volumes:
  - name: scripts
    configMap:
      name: metrics-app-script
      defaultMode: 0755
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-app
  labels:
    app: metrics-app
spec:
  selector:
    app: metrics-app
  ports:
  - port: 8080
    targetPort: 8080
    name: metrics
```

**Deploy application:**

```bash
kubectl apply -f metrics-app.yaml

# Test metrics endpoint
kubectl port-forward pod/metrics-app 8080:8080 &
curl http://localhost:8080
```

### Exercise 2.4: Create ServiceMonitor for Prometheus

**Create ServiceMonitor to scrape metrics:**

```yaml
# servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: metrics-app-monitor
  namespace: default
  labels:
    app: metrics-app
spec:
  selector:
    matchLabels:
      app: metrics-app
  endpoints:
  - port: metrics
    interval: 30s
    path: /
```

**Deploy and verify:**

```bash
kubectl apply -f servicemonitor.yaml

# Check ServiceMonitor
kubectl get servicemonitor metrics-app-monitor

# Wait a minute, then check Prometheus targets
# Go to Prometheus UI: http://localhost:9090/targets
# Search for metrics-app

# Query metrics in Prometheus
# app_requests_total
# rate(app_requests_total[5m])
```

### Exercise 2.5: Create Custom Grafana Dashboard

**Create dashboard JSON:**

```json
{
  "dashboard": {
    "title": "Metrics App Dashboard",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(app_requests_total[5m])"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Current Counter",
        "targets": [
          {
            "expr": "app_counter_current"
          }
        ],
        "type": "stat"
      }
    ]
  }
}
```

**Create ConfigMap for dashboard:**

```yaml
# grafana-dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: metrics-app-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  metrics-app.json: |
    {
      "annotations": {
        "list": []
      },
      "editable": true,
      "fiscalYearStartMonth": 0,
      "graphTooltip": 0,
      "links": [],
      "panels": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "prometheus"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "palette-classic"
              },
              "custom": {
                "axisCenteredZero": false,
                "axisColorMode": "text",
                "axisLabel": "",
                "axisPlacement": "auto",
                "barAlignment": 0,
                "drawStyle": "line",
                "fillOpacity": 10,
                "gradientMode": "none",
                "hideFrom": {
                  "tooltip": false,
                  "viz": false,
                  "legend": false
                },
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "pointSize": 5,
                "scaleDistribution": {
                  "type": "linear"
                },
                "showPoints": "never",
                "spanNulls": false,
                "stacking": {
                  "group": "A",
                  "mode": "none"
                },
                "thresholdsStyle": {
                  "mode": "off"
                }
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": null
                  }
                ]
              },
              "unit": "short"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 0
          },
          "id": 1,
          "options": {
            "legend": {
              "calcs": [],
              "displayMode": "list",
              "placement": "bottom",
              "showLegend": true
            },
            "tooltip": {
              "mode": "single",
              "sort": "none"
            }
          },
          "targets": [
            {
              "expr": "rate(app_requests_total[5m])",
              "refId": "A"
            }
          ],
          "title": "Request Rate",
          "type": "timeseries"
        }
      ],
      "refresh": "5s",
      "schemaVersion": 38,
      "tags": [],
      "templating": {
        "list": []
      },
      "time": {
        "from": "now-15m",
        "to": "now"
      },
      "title": "Metrics App Dashboard",
      "uid": "metrics-app",
      "version": 1
    }
```

**Apply dashboard:**

```bash
kubectl apply -f grafana-dashboard.yaml

# Refresh Grafana UI - dashboard should appear
```

**Questions:**

1. What types of metrics does Prometheus collect (counter, gauge, histogram, summary)?
2. What is the difference between a metric and a label?
3. How does Prometheus service discovery work in Kubernetes?

---

## Part 3: Logging Strategies

### Exercise 3.1: kubectl Logging Commands

**Create multi-container application:**

```yaml
# logging-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logging-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: logging
  template:
    metadata:
      labels:
        app: logging
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["/bin/sh", "-c"]
        args:
        - |
          while true; do
            echo "[APP] $(date -Iseconds) - Processing request"
            sleep 3
          done

      - name: sidecar
        image: busybox:1.36
        command: ["/bin/sh", "-c"]
        args:
        - |
          while true; do
            echo "[SIDECAR] $(date -Iseconds) - Monitoring metrics"
            sleep 5
          done
```

**Deploy and practice logging commands:**

```bash
kubectl apply -f logging-app.yaml

# Get pod names
POD_NAME=$(kubectl get pod -l app=logging -o jsonpath='{.items[0].metadata.name}')

# View logs from specific container
kubectl logs $POD_NAME -c app
kubectl logs $POD_NAME -c sidecar

# View logs from all containers
kubectl logs $POD_NAME --all-containers=true

# Follow logs
kubectl logs $POD_NAME -c app -f

# View last N lines
kubectl logs $POD_NAME -c app --tail=20

# View logs since timestamp
kubectl logs $POD_NAME -c app --since=5m

# View logs with timestamps
kubectl logs $POD_NAME -c app --timestamps

# View previous container logs (if restarted)
kubectl logs $POD_NAME -c app --previous

# Stream logs from all pods with label
kubectl logs -l app=logging --all-containers=true -f --prefix
```

### Exercise 3.2: Log Aggregation Pattern

**Create centralized logging pod:**

```yaml
# log-aggregator.yaml
apiVersion: v1
kind: Pod
metadata:
  name: log-aggregator
spec:
  containers:
  - name: app1
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      while true; do
        echo "{\"service\":\"app1\",\"timestamp\":\"$(date -Iseconds)\",\"level\":\"INFO\",\"message\":\"Processing\"}" >> /logs/app1.log
        sleep 2
      done
    volumeMounts:
    - name: logs
      mountPath: /logs

  - name: app2
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      while true; do
        echo "{\"service\":\"app2\",\"timestamp\":\"$(date -Iseconds)\",\"level\":\"INFO\",\"message\":\"Processing\"}" >> /logs/app2.log
        sleep 3
      done
    volumeMounts:
    - name: logs
      mountPath: /logs

  - name: aggregator
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      while true; do
        if [ -f /logs/app1.log ]; then tail -n 1 /logs/app1.log; fi
        if [ -f /logs/app2.log ]; then tail -n 1 /logs/app2.log; fi
        sleep 1
      done
    volumeMounts:
    - name: logs
      mountPath: /logs
      readOnly: true

  volumes:
  - name: logs
    emptyDir: {}
```

**Deploy and view aggregated logs:**

```bash
kubectl apply -f log-aggregator.yaml

# View aggregated logs
kubectl logs log-aggregator -c aggregator -f
```

### Exercise 3.3: Structured Logging for Analysis

**Create application with structured logs:**

```yaml
# structured-logs-app.yaml
apiVersion: v1
kind: Pod
metadata:
  name: structured-logs-app
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      counter=0
      while true; do
        counter=$((counter + 1))

        # Generate different log levels
        level="INFO"
        status="success"

        if [ $((counter % 10)) -eq 0 ]; then
          level="ERROR"
          status="failed"
        elif [ $((counter % 5)) -eq 0 ]; then
          level="WARN"
          status="timeout"
        fi

        # Structured JSON log
        echo "{\"timestamp\":\"$(date -Iseconds)\",\"level\":\"$level\",\"request_id\":\"req-$counter\",\"status\":\"$status\",\"duration_ms\":$((RANDOM % 1000)),\"pod\":\"$HOSTNAME\"}"

        sleep 2
      done
```

**Deploy and analyze:**

```bash
kubectl apply -f structured-logs-app.yaml

# View raw logs
kubectl logs structured-logs-app

# Filter errors (if jq available)
kubectl logs structured-logs-app | jq 'select(.level=="ERROR")'

# Calculate average duration
kubectl logs structured-logs-app | jq -s 'map(.duration_ms) | add / length'

# Count by status
kubectl logs structured-logs-app | jq -s 'group_by(.status) | map({status: .[0].status, count: length})'
```

**Questions:**

1. What are the advantages of structured logging over plain text?
2. How do you implement log aggregation in production?
3. What should be included in every log entry?

---

## Part 4: Distributed Tracing Concepts

### Exercise 4.1: Understanding Distributed Tracing

**Key concepts:**

- **Trace**: End-to-end journey of a request
- **Span**: Individual operation within a trace
- **Context Propagation**: Passing trace information between services

**Create simulated trace:**

```yaml
# tracing-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: tracing-demo
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

      generate_span_id() {
        cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1
      }

      log_span() {
        local trace_id=$1
        local span_id=$2
        local parent_span_id=$3
        local service=$4
        local operation=$5
        local duration=$6

        echo "{\"trace_id\":\"$trace_id\",\"span_id\":\"$span_id\",\"parent_span_id\":\"$parent_span_id\",\"service\":\"$service\",\"operation\":\"$operation\",\"duration_ms\":$duration,\"timestamp\":\"$(date -Iseconds)\"}"
      }

      while true; do
        trace_id=$(generate_trace_id)

        # Frontend span
        frontend_span=$(generate_span_id)
        log_span "$trace_id" "$frontend_span" "" "frontend" "handle_request" "245"

        sleep 1

        # Backend span (child of frontend)
        backend_span=$(generate_span_id)
        log_span "$trace_id" "$backend_span" "$frontend_span" "backend" "process_data" "180"

        sleep 1

        # Database span (child of backend)
        db_span=$(generate_span_id)
        log_span "$trace_id" "$db_span" "$backend_span" "database" "query" "50"

        sleep 5
      done
```

**Deploy and view traces:**

```bash
kubectl apply -f tracing-demo.yaml

# View trace logs
kubectl logs tracing-demo -f

# Filter by trace ID to see full request path
TRACE_ID=$(kubectl logs tracing-demo --tail=10 | jq -r '.trace_id' | head -n 1)
kubectl logs tracing-demo | jq "select(.trace_id==\"$TRACE_ID\")"
```

### Exercise 4.2: Trace Context Propagation

**Simulate service-to-service tracing:**

```yaml
# multi-service-tracing.yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-service
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      while true; do
        trace_id=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)
        echo "[FRONTEND] trace_id=$trace_id - Incoming request"
        echo "[FRONTEND] trace_id=$trace_id - Calling backend service"
        sleep 5
      done
---
apiVersion: v1
kind: Pod
metadata:
  name: backend-service
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "-c"]
    args:
    - |
      while true; do
        # Simulating receiving trace context
        echo "[BACKEND] trace_id=<propagated> - Processing request"
        echo "[BACKEND] trace_id=<propagated> - Querying database"
        sleep 5
      done
```

**Questions:**

1. What is the difference between logging and tracing?
2. How does distributed tracing help debug microservices?
3. What is context propagation and why is it important?

---

## Part 5: Observability Best Practices

### Exercise 5.1: Golden Signals

**Four Golden Signals (from Google SRE):**

1. **Latency**: Time to service a request
2. **Traffic**: Demand on the system
3. **Errors**: Rate of failed requests
4. **Saturation**: How "full" the service is

**Create application exposing golden signals:**

```yaml
# golden-signals-app.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: golden-signals-script
data:
  app.sh: |
    #!/bin/sh
    REQUESTS=0
    ERRORS=0
    TOTAL_LATENCY=0

    while true; do
      REQUESTS=$((REQUESTS + 1))

      # Simulate latency
      LATENCY=$((RANDOM % 500))
      TOTAL_LATENCY=$((TOTAL_LATENCY + LATENCY))

      # Simulate errors (10% error rate)
      if [ $((RANDOM % 10)) -eq 0 ]; then
        ERRORS=$((ERRORS + 1))
      fi

      # Calculate metrics
      ERROR_RATE=$(awk "BEGIN {print ($ERRORS / $REQUESTS) * 100}")
      AVG_LATENCY=$(awk "BEGIN {print $TOTAL_LATENCY / $REQUESTS}")

      # Expose metrics
      METRICS="# Golden Signals Metrics
    # Latency
    http_request_duration_ms $LATENCY
    http_request_duration_avg_ms $AVG_LATENCY

    # Traffic
    http_requests_total $REQUESTS

    # Errors
    http_errors_total $ERRORS
    http_error_rate $ERROR_RATE

    # Saturation (simulate CPU usage)
    cpu_usage_percent $((RANDOM % 100))"

      echo -e "HTTP/1.1 200 OK\n\n$METRICS" | nc -l -p 8080
    done
---
apiVersion: v1
kind: Pod
metadata:
  name: golden-signals-app
  labels:
    app: golden-signals
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["/bin/sh", "/scripts/app.sh"]
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: scripts
      mountPath: /scripts
  volumes:
  - name: scripts
    configMap:
      name: golden-signals-script
      defaultMode: 0755
```

**Deploy and monitor:**

```bash
kubectl apply -f golden-signals-app.yaml

# Test metrics
kubectl port-forward pod/golden-signals-app 8080:8080 &
curl http://localhost:8080
```

### Exercise 5.2: SLI, SLO, and SLA

**Service Level Indicators (SLI):**

- Metrics that matter to users
- Examples: availability, latency, error rate

**Service Level Objectives (SLO):**

- Target values for SLIs
- Example: 99.9% availability, p95 latency < 200ms

**Service Level Agreements (SLA):**

- Contracts with users
- Consequences if SLO not met

**Create SLO monitoring example:**

```yaml
# slo-monitor.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: slo-rules
data:
  slo.rules: |
    # Availability SLO: 99.9% (error budget: 0.1%)
    groups:
    - name: slo
      interval: 30s
      rules:
      - record: slo:availability:ratio
        expr: 1 - (sum(rate(http_errors_total[5m])) / sum(rate(http_requests_total[5m])))

      - record: slo:latency:p95
        expr: histogram_quantile(0.95, rate(http_request_duration_ms_bucket[5m]))

      # Alert if SLO violated
      - alert: SLOViolation
        expr: slo:availability:ratio < 0.999
        annotations:
          summary: "Availability SLO violated"
```

**Questions:**

1. What are the four golden signals?
2. What's the difference between SLI, SLO, and SLA?
3. How do you determine appropriate SLOs?

---

## Part 6: Alerting

### Exercise 6.1: Create Prometheus Alert Rules

**Create alert rules:**

```yaml
# alert-rules.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alerts
  namespace: monitoring
data:
  alerts.yaml: |
    groups:
    - name: kubernetes-alerts
      rules:
      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} is crash looping"
          description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is restarting frequently"

      - alert: PodNotReady
        expr: kube_pod_status_phase{phase!="Running"} == 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Pod {{ $labels.pod }} not ready"

      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Container {{ $labels.container }} high memory usage"
          description: "Container memory usage is above 90%"

      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Container {{ $labels.container }} high CPU usage"
```

**Apply alert rules:**

```bash
kubectl apply -f alert-rules.yaml

# Check alerts in Prometheus
# Go to: http://localhost:9090/alerts
```

---

## Verification Questions

1. **Metrics:**
   - What is the difference between push and pull metrics?
   - When should you use a counter vs a gauge?
   - What is cardinality and why does it matter?

2. **Logging:**
   - What makes a good log message?
   - How do you handle sensitive data in logs?
   - What's the difference between application and audit logs?

3. **Tracing:**
   - How does tracing differ from logging?
   - What is a span in distributed tracing?
   - How do you propagate trace context?

4. **Observability:**
   - What are the four golden signals?
   - How do you determine what to monitor?
   - What's the difference between monitoring and observability?

---

## Cleanup

```bash
# Delete applications
kubectl delete pod metrics-app log-aggregator structured-logs-app tracing-demo frontend-service backend-service golden-signals-app
kubectl delete deployment logging-app

# Delete monitoring resources
kubectl delete servicemonitor metrics-app-monitor
kubectl delete configmap metrics-app-script logging-config golden-signals-script slo-rules

# Uninstall Prometheus stack (optional)
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring

# Stop port-forwards
pkill -f "port-forward"
```

---

## Challenge Exercise

Create a complete observability stack for a microservices application:

1. **Application with three services:**
   - Frontend
   - Backend API
   - Database

2. **Metrics:**
   - Expose Prometheus metrics for all services
   - Include golden signals
   - Create ServiceMonitors

3. **Logging:**
   - Structured JSON logs
   - Request correlation IDs
   - Different log levels

4. **Tracing:**
   - Simulate distributed traces
   - Propagate trace context
   - Log trace IDs

5. **Dashboards:**
   - Grafana dashboard for each service
   - Overall system health dashboard
   - SLO tracking dashboard

6. **Alerts:**
   - Critical alerts (service down, high error rate)
   - Warning alerts (high latency, high resource usage)
   - SLO violation alerts

**Deliverables:**

- All service manifests
- Prometheus configuration
- Grafana dashboards
- Alert rules
- Documentation of observability strategy
- Runbook for common issues

---

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [OpenTelemetry](https://opentelemetry.io/)
- [Google SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)
- [The Three Pillars of Observability](https://www.oreilly.com/library/view/distributed-systems-observability/9781492033431/)

---

## Key Takeaways

- Observability requires metrics, logs, and traces
- Prometheus is the standard for Kubernetes metrics
- Structured logging enables better analysis
- Distributed tracing helps debug microservices
- Monitor the four golden signals
- Use SLIs/SLOs to define reliability targets
- Alerting should be actionable and relevant
- Dashboards should tell a story about system health
- Context is critical - always include correlation IDs
- Observability is not just monitoring - it's understanding system behavior
