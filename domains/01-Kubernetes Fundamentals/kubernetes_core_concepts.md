# Kubernetes Core Concepts

## Overview
Understanding the fundamental building blocks and architecture of Kubernetes.

## Key Topics

### Kubernetes Architecture
- Control Plane Components
  - API Server
  - etcd
  - Controller Manager
  - Scheduler
- Node Components
  - kubelet
  - kube-proxy
  - Container Runtime

### Core Objects
- **Pods**: Smallest deployable units in Kubernetes
- **Services**: Expose applications running on pods
- **Namespaces**: Virtual clusters for resource isolation
- **Labels and Selectors**: Organize and select groups of objects

### Workload Resources
- Deployments
- ReplicaSets
- StatefulSets
- DaemonSets
- Jobs and CronJobs

## Practice Examples

```yaml
# Example Pod
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

## Study Resources
- [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)
- [Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
- [Pod Overview](https://kubernetes.io/docs/concepts/workloads/pods/)

## Key Points to Remember
- Pods are ephemeral and can be replaced
- Services provide stable networking endpoints
- The control plane manages the cluster state
- Nodes are worker machines that run containerized applications

## Hands-On Practice
- [Lab 01: Kubernetes Core Concepts](../../labs/01-kubernetes-fundamentals/lab-01-kubernetes-core-concepts.md) - Practical exercises covering cluster architecture, pods, deployments, services, and namespaces
