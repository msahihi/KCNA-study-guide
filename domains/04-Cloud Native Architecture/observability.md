# Observability

## Overview

Monitoring, logging, and tracing practices for cloud-native applications.

## Key Topics

### The Three Pillars of Observability

#### 1. Metrics

- Quantitative measurements over time
- Time-series data
- Aggregatable and mathematical operations
- Lower storage overhead

#### 2. Logs

- Discrete events with timestamps
- Detailed contextual information
- Searchable and filterable
- Higher storage requirements

#### 3. Traces

- Request flow across services
- Performance bottleneck identification
- Service dependency mapping
- Distributed system insights

### Monitoring Concepts

#### Types of Monitoring

- **Infrastructure Monitoring**: Node health, resource usage
- **Application Monitoring**: Application metrics, performance
- **Synthetic Monitoring**: Proactive testing of endpoints
- **Real User Monitoring (RUM)**: Actual user experience data

#### Key Metrics

- **RED Method** (for services):
  - Rate: Requests per second
  - Errors: Failed requests
  - Duration: Latency/response time

- **USE Method** (for resources):
  - Utilization: How busy is the resource
  - Saturation: How much work is queued
  - Errors: Error count

- **Four Golden Signals**:
  - Latency
  - Traffic
  - Errors
  - Saturation

### Prometheus

#### Overview

- Open-source monitoring and alerting toolkit
- CNCF graduated project
- Time-series database
- Pull-based metrics collection
- PromQL query language

#### Architecture Components

- **Prometheus Server**: Scrapes and stores metrics
- **Exporters**: Expose metrics from applications
- **Alertmanager**: Handles alerts
- **Pushgateway**: For short-lived jobs

#### Metrics Types

- **Counter**: Cumulative value that only increases
- **Gauge**: Value that can go up or down
- **Histogram**: Observations in configurable buckets
- **Summary**: Similar to histogram with quantiles

### Grafana

#### Overview

- Visualization and analytics platform
- Multi-datasource support
- Dashboarding and alerting
- Rich plugin ecosystem

#### Features

- Custom dashboards
- Templated dashboards
- Alert rules and notifications
- Data source plugins

### Logging in Cloud Native

#### Logging Patterns

- Centralized logging
- Structured logging (JSON)
- Log aggregation
- Log rotation and retention

#### Log Collection

- **Fluentd/Fluent Bit**: Log collector and processor
- **Logstash**: Data processing pipeline
- **Vector**: High-performance observability data pipeline

#### Log Storage and Analysis

- **Elasticsearch**: Search and analytics engine
- **Loki**: Log aggregation system (Prometheus-like)
- **Splunk**: Enterprise logging platform

### Distributed Tracing

#### Concepts

- **Span**: Single operation in a trace
- **Trace**: Collection of spans representing a request
- **Context Propagation**: Passing trace context across services
- **Sampling**: Selecting which traces to record

#### Tracing Tools

- **Jaeger**: End-to-end distributed tracing
- **Zipkin**: Distributed tracing system
- **OpenTelemetry**: Unified observability framework

### OpenTelemetry

#### Overview

- CNCF observability framework
- Vendor-neutral APIs and SDKs
- Unified approach to metrics, logs, and traces
- Automatic instrumentation support

#### Components

- **API**: Language-specific interfaces
- **SDK**: Implementation of the API
- **Collector**: Receive, process, and export telemetry
- **Instrumentation**: Auto and manual instrumentation

### Service Mesh Observability

#### Service Mesh Features

- Automatic metrics collection
- Distributed tracing
- Traffic visualization
- Service topology mapping

#### Popular Service Meshes

- **Istio**: Feature-rich service mesh
- **Linkerd**: Lightweight service mesh
- **Consul**: Service networking solution

## Examples

### Prometheus Metrics Endpoint

```python
from prometheus_client import Counter, Gauge, Histogram, start_http_server
import time

# Define metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total requests')
REQUEST_DURATION = Histogram('app_request_duration_seconds', 'Request duration')
ACTIVE_USERS = Gauge('app_active_users', 'Active users')

# Start metrics server
start_http_server(8000)

# Instrument code
REQUEST_COUNT.inc()
with REQUEST_DURATION.time():
    # Process request
    time.sleep(0.1)
```

### Prometheus Configuration

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
```

### PromQL Queries

```promql
# CPU usage by pod
rate(container_cpu_usage_seconds_total[5m])

# Memory usage percentage
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100

# Request rate
rate(http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rate
rate(http_requests_total{status=~"5.."}[5m])
```

### Grafana Dashboard JSON (excerpt)

```json
{
  "dashboard": {
    "title": "Application Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{service}}"
          }
        ],
        "type": "graph"
      }
    ]
  }
}
```

### Structured Logging Example

```json
{
  "timestamp": "2026-01-25T10:30:45.123Z",
  "level": "INFO",
  "service": "order-service",
  "traceId": "abc123",
  "spanId": "xyz789",
  "message": "Order created successfully",
  "orderId": "order-12345",
  "userId": "user-67890",
  "amount": 99.99,
  "duration_ms": 45
}
```

### OpenTelemetry Instrumentation (Python)

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger import JaegerExporter

# Configure tracing
trace.set_tracer_provider(TracerProvider())
jaeger_exporter = JaegerExporter(
    agent_host_name="localhost",
    agent_port=6831,
)
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)

# Use tracer
tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("process_order"):
    # Your code here
    pass
```

## Observability Best Practices

1. **Implement all three pillars**: Metrics, logs, and traces
2. **Use structured logging**: JSON format for better parsing
3. **Add context**: Include correlation IDs, user IDs, etc.
4. **Set up alerts**: Proactive monitoring with meaningful alerts
5. **Create dashboards**: Visualize key metrics
6. **Sample strategically**: Balance detail with cost
7. **Monitor SLIs/SLOs**: Service Level Indicators and Objectives
8. **Document runbooks**: Link alerts to troubleshooting steps

## Common Observability Patterns

### Golden Signals Dashboard

- Request rate (traffic)
- Error rate
- Request duration (latency)
- Resource saturation

### SLI/SLO/SLA

- **SLI**: Service Level Indicator (actual measurement)
- **SLO**: Service Level Objective (target)
- **SLA**: Service Level Agreement (contract)

### Alert Fatigue Prevention

- Set meaningful thresholds
- Use proper alert severity
- Implement alert grouping
- Create runbooks for alerts
- Regularly review and tune alerts

## Study Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [The Three Pillars of Observability](https://www.oreilly.com/library/view/distributed-systems-observability/9781492033431/)

## Key Points to Remember

- Observability enables understanding system behavior from outputs
- Metrics, logs, and traces provide complementary insights
- Prometheus is the de facto standard for Kubernetes metrics
- Use structured logging for better analysis
- Distributed tracing is essential for microservices
- OpenTelemetry provides vendor-neutral observability
- Monitor the four golden signals: latency, traffic, errors, saturation
- Create dashboards for key business and technical metrics

## Hands-On Practice

- [Lab 01: Observability](../../labs/04-cloud-native-architecture/lab-01-observability.md) - Practical exercises covering Prometheus, Grafana, logging, metrics, and alerting
