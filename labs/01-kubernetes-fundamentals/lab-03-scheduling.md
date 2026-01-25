# Lab 03: Kubernetes Scheduling

## Objectives
- Understand how the Kubernetes scheduler works
- Use nodeSelector for simple node selection
- Implement node affinity and anti-affinity
- Work with taints and tolerations
- Understand pod priority and preemption

## Prerequisites
- Kubernetes cluster with multiple nodes (or minikube with multiple nodes)
- kubectl configured

## Exercise 1: Node Labels and nodeSelector

### Task 1.1: Label Nodes
```bash
# View current nodes and their labels
kubectl get nodes --show-labels

# Add a label to a node
kubectl label nodes <node-name> disktype=ssd

# Add multiple labels
kubectl label nodes <node-name> environment=production zone=us-east-1a

# View specific labels
kubectl get nodes -L disktype,environment

# Remove a label
kubectl label nodes <node-name> disktype-
```

### Task 1.2: Use nodeSelector
Create `pod-nodeselector.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-ssd
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: nginx
    image: nginx
```

```bash
# Create the pod
kubectl apply -f pod-nodeselector.yaml

# Verify pod is scheduled on correct node
kubectl get pod nginx-ssd -o wide

# Try creating pod with non-existent label (will remain Pending)
kubectl run test-pod --image=nginx --overrides='{"spec":{"nodeSelector":{"disktype":"nvme"}}}'
kubectl get pod test-pod
kubectl describe pod test-pod | grep -A 5 Events
```

## Exercise 2: Node Affinity

### Task 2.1: Required Node Affinity
Create `pod-node-affinity-required.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-node-affinity
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
            - nvme
  containers:
  - name: nginx
    image: nginx
```

```bash
# Create the pod
kubectl apply -f pod-node-affinity-required.yaml

# Check where it was scheduled
kubectl get pod nginx-node-affinity -o wide
```

### Task 2.2: Preferred Node Affinity
Create `pod-node-affinity-preferred.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-preferred
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 80
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
      - weight: 20
        preference:
          matchExpressions:
          - key: environment
            operator: In
            values:
            - production
  containers:
  - name: nginx
    image: nginx
```

```bash
# Create the pod
kubectl apply -f pod-node-affinity-preferred.yaml

# Verify scheduling
kubectl get pod nginx-preferred -o wide
```

## Exercise 3: Pod Affinity and Anti-Affinity

### Task 3.1: Pod Affinity
Create `web-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx
```

Create `cache-with-affinity.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web
            topologyKey: kubernetes.io/hostname
      containers:
      - name: redis
        image: redis
```

```bash
# Deploy web server first
kubectl apply -f web-deployment.yaml

# Deploy cache with affinity
kubectl apply -f cache-with-affinity.yaml

# Verify pods are co-located
kubectl get pods -o wide -l app=web
kubectl get pods -o wide -l app=cache
```

### Task 3.2: Pod Anti-Affinity
Create `web-anti-affinity.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-ha
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-ha
  template:
    metadata:
      labels:
        app: web-ha
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web-ha
            topologyKey: kubernetes.io/hostname
      containers:
      - name: nginx
        image: nginx
```

```bash
# Create deployment with anti-affinity
kubectl apply -f web-anti-affinity.yaml

# Verify pods are on different nodes
kubectl get pods -l app=web-ha -o wide
```

## Exercise 4: Taints and Tolerations

### Task 4.1: Add Taints to Nodes
```bash
# Add a taint to a node
kubectl taint nodes <node-name> key=value:NoSchedule

# Add taint with NoExecute effect
kubectl taint nodes <node-name> dedicated=special-workload:NoExecute

# View taints on nodes
kubectl describe node <node-name> | grep Taints

# Remove a taint
kubectl taint nodes <node-name> key=value:NoSchedule-
```

### Task 4.2: Create Pods with Tolerations
Create `pod-with-toleration.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-toleration
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

```bash
# Create pod with toleration
kubectl apply -f pod-with-toleration.yaml

# Verify it was scheduled on tainted node
kubectl get pod nginx-toleration -o wide
```

### Task 4.3: Tolerate All Taints
Create `pod-tolerate-all.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tolerate-all
spec:
  tolerations:
  - operator: "Exists"
  containers:
  - name: nginx
    image: nginx
```

```bash
# Create pod that tolerates all taints
kubectl apply -f pod-tolerate-all.yaml
```

## Exercise 5: DaemonSet

### Task 5.1: Create a DaemonSet
Create `logging-daemonset.yaml`:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: logging-agent
spec:
  selector:
    matchLabels:
      name: logging-agent
  template:
    metadata:
      labels:
        name: logging-agent
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.14
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
```

```bash
# Create DaemonSet
kubectl apply -f logging-daemonset.yaml

# Verify one pod per node
kubectl get daemonset logging-agent
kubectl get pods -l name=logging-agent -o wide

# Check DaemonSet status
kubectl describe daemonset logging-agent
```

## Exercise 6: Resource-Based Scheduling

### Task 6.1: Create Pods with Resource Requests
Create `high-resource-pod.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: high-resource
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"
```

```bash
# Create pod
kubectl apply -f high-resource-pod.yaml

# Check node resources
kubectl describe nodes | grep -A 5 "Allocated resources"

# View pod resource allocation
kubectl top nodes
kubectl top pods
```

## Exercise 7: Manual Scheduling

### Task 7.1: Manually Schedule a Pod
Create `manually-scheduled-pod.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: manual-schedule
spec:
  nodeName: <node-name>  # Replace with actual node name
  containers:
  - name: nginx
    image: nginx
```

```bash
# Create manually scheduled pod
kubectl apply -f manually-scheduled-pod.yaml

# Verify it's on the specified node
kubectl get pod manual-schedule -o wide
```

## Exercise 8: Pod Priority and Preemption

### Task 8.1: Create Priority Classes
Create `priority-classes.yaml`:
```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
description: "High priority class"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 1000
globalDefault: false
description: "Low priority class"
```

```bash
# Create priority classes
kubectl apply -f priority-classes.yaml

# View priority classes
kubectl get priorityclasses
```

### Task 8.2: Use Priority Classes
Create `high-priority-pod.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: high-pri-pod
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        memory: "100Mi"
        cpu: "100m"
```

```bash
# Create pod with high priority
kubectl apply -f high-priority-pod.yaml

# Check pod priority
kubectl get pod high-pri-pod -o yaml | grep priority
```

## Cleanup
```bash
# Delete all resources
kubectl delete pod nginx-ssd nginx-node-affinity nginx-preferred nginx-toleration tolerate-all manual-schedule high-pri-pod test-pod
kubectl delete deployment web-server cache-server web-ha
kubectl delete daemonset logging-agent
kubectl delete priorityclass high-priority low-priority

# Remove node labels
kubectl label nodes <node-name> disktype- environment- zone-

# Remove taints
kubectl taint nodes <node-name> key:NoSchedule-
kubectl taint nodes <node-name> dedicated:NoExecute-
```

## Challenge Exercise

Create a complex scheduling scenario:
1. Label three nodes with different zones (zone=us-east-1a, us-east-1b, us-east-1c)
2. Create a deployment with 6 replicas that:
   - Uses pod anti-affinity to spread across zones
   - Prefers nodes with SSD
   - Has high priority
   - Includes resource requests
3. Verify pods are distributed correctly

## Verification Checklist

- [ ] Used nodeSelector for node selection
- [ ] Implemented node affinity (required and preferred)
- [ ] Used pod affinity and anti-affinity
- [ ] Applied taints and tolerations
- [ ] Created and managed DaemonSets
- [ ] Understood resource-based scheduling
- [ ] Manually scheduled pods
- [ ] Configured pod priorities

## Additional Resources
- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
