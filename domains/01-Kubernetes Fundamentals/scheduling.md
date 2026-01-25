# Scheduling

## Overview
How Kubernetes schedules pods onto nodes and related scheduling mechanisms.

## Key Topics

### Kubernetes Scheduler
- How the scheduler works
- Scheduling workflow
- Default scheduler behavior
- Custom schedulers

### Node Selection
- **Node Selector**: Simple node selection based on labels
- **Node Affinity**: More expressive node selection rules
- **Taints and Tolerations**: Control which pods can be scheduled on nodes
- **Pod Affinity/Anti-Affinity**: Schedule pods relative to other pods

### Resource-Based Scheduling
- Resource requests and limits
- Quality of Service (QoS) classes
  - Guaranteed
  - Burstable
  - BestEffort
- Pod Priority and Preemption

### Advanced Scheduling
- Pod Topology Spread Constraints
- DaemonSets (schedule pods on all/specific nodes)
- Static Pods
- Manual scheduling (nodeName field)

## Examples

### Node Selector
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: nginx
    image: nginx
```

### Taints and Tolerations
```yaml
# Taint a node
kubectl taint nodes node1 key=value:NoSchedule

# Pod with toleration
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx
```

## Study Resources
- [Kubernetes Scheduler](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/)
- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

## Key Points to Remember
- The scheduler finds the best node for each pod
- Node selectors provide basic node selection
- Taints repel pods, tolerations allow pods to tolerate taints
- Resource requests affect scheduling decisions
- Affinity rules allow more complex pod placement

## Hands-On Practice
- [Lab 03: Scheduling](../../labs/01-kubernetes-fundamentals/lab-03-scheduling.md) - Practical exercises covering node selection, affinity, taints/tolerations, and DaemonSets
