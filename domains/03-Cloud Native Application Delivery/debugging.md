# Debugging

## Overview
Techniques and tools for debugging cloud-native applications in production environments.

## Key Topics

### Application-Level Debugging

#### Log Analysis
- Structured logging (JSON format)
- Log aggregation and centralization
- Log levels (DEBUG, INFO, WARN, ERROR)
- Correlation IDs for tracing requests
- Context-aware logging

#### Application Metrics
- Custom application metrics
- Business metrics
- Performance metrics
- Error rates and latency

#### Health Checks
- Liveness probes: Is the container alive?
- Readiness probes: Is the container ready to serve traffic?
- Startup probes: Has the application started?

### Debugging Tools and Techniques

#### kubectl Debug Commands
```bash
# View logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous
kubectl logs -f <pod-name>  # follow logs

# Execute commands in container
kubectl exec <pod-name> -- <command>
kubectl exec -it <pod-name> -- /bin/bash

# Copy files
kubectl cp <pod-name>:/path/to/file ./local-file

# Port forwarding for local debugging
kubectl port-forward <pod-name> 8080:8080

# Describe resources
kubectl describe pod <pod-name>
kubectl get events
```

#### Ephemeral Debug Containers
```bash
# Add debug container to running pod (K8s 1.23+)
kubectl debug <pod-name> -it --image=busybox --target=<container-name>

# Create copy of pod with debugging tools
kubectl debug <pod-name> -it --image=ubuntu --share-processes --copy-to=debug-pod
```

### Distributed Tracing

#### Tracing Concepts
- Spans: Individual operations in a trace
- Traces: End-to-end request path
- Context propagation across services
- Sampling strategies

#### Tracing Tools
- **Jaeger**: Distributed tracing platform
- **Zipkin**: Distributed tracing system
- **OpenTelemetry**: Vendor-neutral observability framework
- Service mesh tracing (Istio, Linkerd)

### Logging Solutions

#### Log Aggregation Platforms
- **ELK Stack**: Elasticsearch, Logstash, Kibana
- **EFK Stack**: Elasticsearch, Fluentd, Kibana
- **Loki**: Log aggregation system by Grafana Labs
- **Splunk**: Enterprise logging and monitoring

#### Best Practices
- Use structured logging (JSON)
- Include timestamps and context
- Log at appropriate levels
- Centralize logs from all services
- Implement log retention policies

### Profiling and Performance

#### Application Profiling
- CPU profiling
- Memory profiling
- Goroutine/thread profiling
- Heap analysis

#### Tools
- pprof (Go)
- Java Flight Recorder
- Python profilers
- Node.js profiling tools

### Common Debugging Scenarios

#### Application Crashes
1. Check logs: `kubectl logs <pod-name> --previous`
2. Check events: `kubectl describe pod <pod-name>`
3. Verify resource limits
4. Check liveness probe configuration
5. Review application error handling

#### Slow Performance
1. Check resource usage: `kubectl top pods`
2. Review application metrics
3. Analyze traces for bottlenecks
4. Check network latency
5. Profile application code

#### Intermittent Issues
1. Enable detailed logging
2. Add distributed tracing
3. Monitor error patterns
4. Check resource contention
5. Review autoscaling behavior

#### Memory Leaks
1. Monitor memory usage over time
2. Generate heap dumps
3. Use memory profiling tools
4. Review object lifecycle
5. Check for unclosed connections

## Examples

### Health Check Configuration
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0
    ports:
    - containerPort: 8080
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      timeoutSeconds: 3
      successThreshold: 1
    startupProbe:
      httpGet:
        path: /startup
        port: 8080
      failureThreshold: 30
      periodSeconds: 10
```

### Structured Logging Example (JSON)
```json
{
  "timestamp": "2026-01-25T10:30:45.123Z",
  "level": "ERROR",
  "service": "user-service",
  "traceId": "abc123xyz",
  "spanId": "span456",
  "message": "Failed to fetch user data",
  "error": "connection timeout",
  "userId": "user-789",
  "duration_ms": 5000
}
```

### Debug Pod with Tools
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-tools
spec:
  containers:
  - name: debug
    image: nicolaka/netshoot
    command: ['sh', '-c', 'sleep 3600']
    # This pod contains: curl, wget, dig, nslookup, netstat, etc.
```

### OpenTelemetry Configuration Example
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
data:
  config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
          http:
    processors:
      batch:
    exporters:
      jaeger:
        endpoint: jaeger:14250
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [jaeger]
```

## Debugging Checklist

1. **Check Pod Status**
   - Is the pod running?
   - Are all containers ready?

2. **Review Logs**
   - Current and previous logs
   - All containers in the pod

3. **Check Events**
   - Recent events for the pod
   - Cluster-wide events

4. **Verify Configuration**
   - Environment variables
   - ConfigMaps and Secrets
   - Resource requests/limits

5. **Test Connectivity**
   - Service endpoints
   - DNS resolution
   - Network policies

6. **Monitor Resources**
   - CPU usage
   - Memory usage
   - Disk space

7. **Analyze Traces**
   - Request flow
   - Latency bottlenecks
   - Error propagation

## Study Resources
- [Debug Running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)
- [Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)
- [OpenTelemetry](https://opentelemetry.io/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)

## Key Points to Remember
- Always check logs first when debugging
- Use structured logging for better analysis
- Implement proper health checks (liveness, readiness, startup)
- Distributed tracing is essential for microservices
- Use ephemeral debug containers for live debugging
- Monitor application metrics continuously
- Profile applications to identify performance issues
- Keep debug tools in a separate container image

## Hands-On Practice
- [Lab 02: Debugging](../../labs/03-cloud-native-application-delivery/lab-02-debugging.md) - Practical exercises covering health probes, logging, debugging techniques, and graceful shutdown
