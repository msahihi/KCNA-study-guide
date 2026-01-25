# KCNA Labs - Hands-On Exercises

Welcome to the KCNA (Kubernetes and Cloud Native Associate) hands-on labs! These practical exercises are designed to reinforce your understanding of Kubernetes and cloud-native concepts through real-world scenarios and hands-on practice.

## Lab Structure

The labs are organized by the four KCNA exam domains, with each lab covering specific topics within those domains. Each lab includes:

- **Clear Objectives**: What you'll learn
- **Prerequisites**: What you need before starting
- **Step-by-Step Exercises**: Practical tasks with detailed instructions
- **YAML Manifests**: Ready-to-use configuration files
- **kubectl Commands**: Commands you can run directly
- **Verification Questions**: Test your understanding
- **Cleanup Instructions**: Remove resources after completion
- **Challenge Exercises**: Advanced scenarios to test mastery

## Prerequisites

Before starting these labs, ensure you have:

1. **Kubernetes Cluster**: One of the following:
   - Minikube (recommended for local development)
   - Kind (Kubernetes in Docker)
   - Docker Desktop with Kubernetes enabled
   - Cloud provider managed Kubernetes (EKS, GKE, AKS)

2. **Tools Installed**:
   - kubectl (Kubernetes command-line tool)
   - Docker or Podman (for container operations)
   - Text editor (VS Code, vim, nano, etc.)

3. **Basic Knowledge**:
   - Linux command line basics
   - Basic understanding of containers
   - YAML syntax

## Setting Up Your Lab Environment

### Option 1: Minikube (Recommended)
```bash
# Install minikube
# macOS
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start minikube
minikube start --nodes=3 --driver=docker

# Verify
kubectl get nodes
```

### Option 2: Kind
```bash
# Install kind
# macOS
brew install kind

# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

# Verify
kubectl get nodes
```

## Lab Domains

### Domain 1: Kubernetes Fundamentals (44%)

#### [Lab 01: Kubernetes Core Concepts](01-kubernetes-fundamentals/lab-01-kubernetes-core-concepts.md)
**Duration**: 90 minutes | **Difficulty**: Beginner

Learn the foundational concepts of Kubernetes:
- Explore cluster architecture and components
- Create and manage Pods
- Work with Deployments and ReplicaSets
- Understand Services and networking
- Use Namespaces for resource isolation
- Apply labels and selectors

**Key Skills**: Pod creation, Deployments, Services, Namespaces, Labels

---

#### [Lab 02: Administration](01-kubernetes-fundamentals/lab-02-administration.md)
**Duration**: 120 minutes | **Difficulty**: Intermediate

Master Kubernetes administration tasks:
- kubectl configuration and contexts
- ConfigMaps for application configuration
- Secrets management
- RBAC (Role-Based Access Control)
- Resource requests and limits
- LimitRanges and ResourceQuotas

**Key Skills**: kubectl, ConfigMaps, Secrets, RBAC, Resource management

---

#### [Lab 03: Scheduling](01-kubernetes-fundamentals/lab-03-scheduling.md)
**Duration**: 120 minutes | **Difficulty**: Intermediate

Understand how Kubernetes schedules pods:
- Node labels and nodeSelector
- Node affinity and anti-affinity
- Pod affinity and anti-affinity
- Taints and tolerations
- DaemonSets
- Pod priority and preemption

**Key Skills**: Scheduling, Node selection, Affinity rules, Taints

---

#### [Lab 04: Containerization](01-kubernetes-fundamentals/lab-04-containerization.md)
**Duration**: 120 minutes | **Difficulty**: Intermediate

Deep dive into container fundamentals:
- Container runtimes (containerd, CRI-O)
- Building container images
- Image best practices
- Multi-container patterns (sidecar, adapter, ambassador)
- Init containers
- Container security

**Key Skills**: Containers, Image building, Multi-container pods, Init containers

---

### Domain 2: Container Orchestration (28%)

#### [Lab 01: Networking](02-container-orchestration/lab-01-networking.md)
**Duration**: 120 minutes | **Difficulty**: Intermediate

Master Kubernetes networking:
- CNI plugins and configuration
- Service types (ClusterIP, NodePort, LoadBalancer, Headless)
- Ingress controllers and resources
- Network Policies
- DNS in Kubernetes
- Service mesh basics

**Key Skills**: Services, Ingress, Network Policies, DNS, CNI

---

#### [Lab 02: Security](02-container-orchestration/lab-02-security.md)
**Duration**: 120 minutes | **Difficulty**: Advanced

Implement Kubernetes security best practices:
- Security contexts (pod and container level)
- Pod Security Standards (Privileged, Baseline, Restricted)
- RBAC for access control
- Secrets management and encryption
- Network Policies for isolation
- Image security and scanning

**Key Skills**: Security contexts, Pod Security, RBAC, Network isolation

---

#### [Lab 03: Troubleshooting](02-container-orchestration/lab-03-troubleshooting.md)
**Duration**: 120 minutes | **Difficulty**: Intermediate

Learn systematic troubleshooting:
- kubectl debug commands
- Common pod issues (ImagePullBackOff, CrashLoopBackOff, Pending)
- Ephemeral debug containers
- Service connectivity issues
- DNS troubleshooting
- Resource issues

**Key Skills**: Debugging, kubectl logs, Events, Troubleshooting methodology

---

#### [Lab 04: Storage](02-container-orchestration/lab-04-storage.md)
**Duration**: 120 minutes | **Difficulty**: Intermediate

Manage persistent storage in Kubernetes:
- Volume types (emptyDir, hostPath, ConfigMap, Secret)
- PersistentVolumes (PV) and PersistentVolumeClaims (PVC)
- StorageClasses and dynamic provisioning
- StatefulSets with persistent storage
- Volume snapshots and cloning

**Key Skills**: Volumes, PV/PVC, StorageClasses, StatefulSets

---

### Domain 3: Cloud Native Application Delivery (16%)

#### [Lab 01: Application Delivery](03-cloud-native-application-delivery/lab-01-application-delivery.md)
**Duration**: 120 minutes | **Difficulty**: Advanced

Implement modern deployment strategies:
- Rolling updates and rollbacks
- Blue-Green deployments
- Canary deployments
- Helm package manager (install, create charts, upgrade)
- GitOps with Kustomize
- Progressive delivery patterns

**Key Skills**: Deployments, Helm, Kustomize, GitOps, Deployment strategies

---

#### [Lab 02: Debugging](03-cloud-native-application-delivery/lab-02-debugging.md)
**Duration**: 120 minutes | **Difficulty**: Intermediate

Debug cloud-native applications:
- Health checks (liveness, readiness, startup probes)
- Application-level debugging
- Structured logging (JSON format)
- Log aggregation patterns
- Graceful shutdown
- Performance profiling

**Key Skills**: Health probes, Logging, Application debugging, Graceful shutdown

---

### Domain 4: Cloud Native Architecture (12%)

#### [Lab 01: Observability](04-cloud-native-architecture/lab-01-observability.md)
**Duration**: 120 minutes | **Difficulty**: Advanced

Implement observability in Kubernetes:
- Prometheus metrics collection
- Grafana dashboards
- Logging strategies (EFK/ELK stack basics)
- Distributed tracing concepts
- The three pillars (Metrics, Logs, Traces)
- SLI/SLO/SLA and alerting

**Key Skills**: Prometheus, Grafana, Logging, Metrics, Alerting

---

#### [Lab 02: Cloud Native Ecosystem and Principles](04-cloud-native-architecture/lab-02-cloud-native-ecosystem.md)
**Duration**: 90 minutes | **Difficulty**: Beginner

Explore the cloud-native ecosystem:
- CNCF landscape and project maturity levels
- Cloud-native principles
- 12-factor app methodology (all 12 factors)
- Cloud-native patterns (sidecar, circuit breaker, etc.)
- Service mesh concepts
- Serverless basics

**Key Skills**: CNCF projects, 12-factor app, Cloud-native patterns

---

#### [Lab 03: Cloud Native Community and Collaboration](04-cloud-native-architecture/lab-03-community.md)
**Duration**: 90 minutes | **Difficulty**: Beginner

Engage with the cloud-native community:
- CNCF and Kubernetes community structure
- Communication channels (Slack, mailing lists, forums)
- Contributing to open source (code, docs, community)
- Special Interest Groups (SIGs)
- KubeCon and local events
- Building your cloud-native career

**Key Skills**: Open source contribution, Community participation, CNCF structure

---

## Lab Progression Path

### Beginner Path (Start Here)
1. Lab 01: Kubernetes Core Concepts
2. Lab 02: Cloud Native Ecosystem and Principles
3. Lab 04: Containerization
4. Lab 03: Community and Collaboration

### Intermediate Path
5. Lab 02: Administration
6. Lab 03: Scheduling
7. Lab 01: Networking
8. Lab 04: Storage
9. Lab 03: Troubleshooting
10. Lab 02: Debugging (Cloud Native App Delivery)

### Advanced Path
11. Lab 02: Security
12. Lab 01: Application Delivery
13. Lab 01: Observability

## Lab Tips

### Before Starting Each Lab

1. **Read the entire lab**: Understand objectives and flow
2. **Check prerequisites**: Ensure you have required tools
3. **Set up a clean environment**: Start with a fresh namespace
4. **Have documentation handy**: Keep Kubernetes docs open

### During the Lab

1. **Type commands manually**: Don't just copy-paste (muscle memory helps!)
2. **Read error messages carefully**: They often tell you what's wrong
3. **Experiment**: Try variations of the exercises
4. **Take notes**: Document what you learn
5. **Ask questions**: Use the provided verification questions

### After Completing Each Lab

1. **Clean up resources**: Follow cleanup instructions
2. **Complete the challenge exercise**: Test your mastery
3. **Review key concepts**: Ensure you understand the takeaways
4. **Document your experience**: Note any difficulties or insights

## Common Issues and Solutions

### Cluster Not Responding
```bash
# Check cluster status
kubectl cluster-info
minikube status  # if using minikube

# Restart cluster
minikube stop && minikube start
```

### Pods Stuck in Pending
```bash
# Check events
kubectl describe pod <pod-name>

# Check node resources
kubectl describe nodes

# Check for taints
kubectl describe nodes | grep Taints
```

### Permission Denied Errors
```bash
# Check RBAC permissions
kubectl auth can-i create pods

# Use admin credentials
kubectl --as=admin get pods
```

## Additional Resources

### Official Documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [CNCF Website](https://www.cncf.io/)

### Interactive Learning
- [Kubernetes Playground (Killercoda)](https://killercoda.com/playgrounds/scenario/kubernetes)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)

### Practice Exams
- [KCNA Practice Questions](https://github.com/cncf/curriculum/tree/master/kcna)
- Mock exam questions in this repository

### Community
- [Kubernetes Slack](https://kubernetes.slack.com/)
- [CNCF Slack](https://cloud-native.slack.com/)
- [r/kubernetes](https://reddit.com/r/kubernetes)

## Lab Completion Tracker

Track your progress through the labs:

### Kubernetes Fundamentals (44%)
- [ ] Lab 01: Kubernetes Core Concepts
- [ ] Lab 02: Administration
- [ ] Lab 03: Scheduling
- [ ] Lab 04: Containerization

### Container Orchestration (28%)
- [ ] Lab 01: Networking
- [ ] Lab 02: Security
- [ ] Lab 03: Troubleshooting
- [ ] Lab 04: Storage

### Cloud Native Application Delivery (16%)
- [ ] Lab 01: Application Delivery
- [ ] Lab 02: Debugging

### Cloud Native Architecture (12%)
- [ ] Lab 01: Observability
- [ ] Lab 02: Cloud Native Ecosystem and Principles
- [ ] Lab 03: Cloud Native Community and Collaboration

## Estimated Total Time

- **Total Lab Time**: ~22 hours of hands-on practice
- **Recommended Pace**: 2-3 labs per week over 4-5 weeks
- **Final Week**: Review and complete challenge exercises
