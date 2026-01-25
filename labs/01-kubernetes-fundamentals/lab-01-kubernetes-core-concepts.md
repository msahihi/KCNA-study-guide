# Lab 01: Kubernetes Core Concepts

## Objectives
- Understand Kubernetes architecture components
- Create and manage Pods
- Work with Deployments and ReplicaSets
- Use Services for networking
- Work with Namespaces

## Prerequisites
- Access to a Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl installed and configured

## Exercise 1: Explore Cluster Components

### Task 1.1: Check Cluster Information
```bash
# Get cluster info
kubectl cluster-info

# View all nodes
kubectl get nodes

# Describe a node to see details
kubectl describe node <node-name>

# Check control plane components
kubectl get pods -n kube-system
```

**Questions:**
1. What components are running in the kube-system namespace?
2. What is the role of the kube-apiserver?
3. How many nodes are in your cluster?

## Exercise 2: Working with Pods

### Task 2.1: Create a Simple Pod
Create a file `nginx-pod.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
```

```bash
# Create the pod
kubectl apply -f nginx-pod.yaml

# View the pod
kubectl get pods

# Get detailed information
kubectl describe pod nginx-pod

# View pod logs
kubectl logs nginx-pod

# Execute a command in the pod
kubectl exec nginx-pod -- nginx -v
```

### Task 2.2: Create a Multi-Container Pod
Create `multi-container-pod.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  - name: debian
    image: debian:bullseye-slim
    command: ["/bin/sh"]
    args: ["-c", "while true; do date >> /data/index.html; sleep 5; done"]
    volumeMounts:
    - name: shared-data
      mountPath: /data
  volumes:
  - name: shared-data
    emptyDir: {}
```

```bash
# Create the pod
kubectl apply -f multi-container-pod.yaml

# Check both containers are running
kubectl get pod multi-container-pod

# Test the shared volume
kubectl exec multi-container-pod -c nginx -- cat /usr/share/nginx/html/index.html

# View logs from specific container
kubectl logs multi-container-pod -c debian
```

**Questions:**
1. How do containers in the same pod share data?
2. What is the purpose of the emptyDir volume?

## Exercise 3: Working with Deployments

### Task 3.1: Create a Deployment
Create `nginx-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
```

```bash
# Create deployment
kubectl apply -f nginx-deployment.yaml

# View deployments
kubectl get deployments

# View ReplicaSets created by deployment
kubectl get replicasets

# View pods created by deployment
kubectl get pods -l app=nginx

# Scale the deployment
kubectl scale deployment nginx-deployment --replicas=5

# Check the scaling
kubectl get pods -l app=nginx
```

### Task 3.2: Update a Deployment
```bash
# Update the image
kubectl set image deployment/nginx-deployment nginx=nginx:1.22

# Check rollout status
kubectl rollout status deployment/nginx-deployment

# View rollout history
kubectl rollout history deployment/nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment

# Rollback to specific revision
kubectl rollout undo deployment/nginx-deployment --to-revision=1
```

**Questions:**
1. What is the difference between a Pod and a Deployment?
2. How does a Deployment ensure the desired number of pods?

## Exercise 4: Working with Services

### Task 4.1: Create a ClusterIP Service
Create `nginx-service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

```bash
# Create the service
kubectl apply -f nginx-service.yaml

# View the service
kubectl get services

# Describe the service
kubectl describe service nginx-service

# View the endpoints
kubectl get endpoints nginx-service

# Test the service from within cluster
kubectl run curl-test --image=curlimages/curl -i --rm --restart=Never -- curl nginx-service
```

### Task 4.2: Create a NodePort Service
Create `nginx-nodeport.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

```bash
# Create the service
kubectl apply -f nginx-nodeport.yaml

# View the service
kubectl get service nginx-nodeport

# Access the service (if using minikube)
minikube service nginx-nodeport --url
```

## Exercise 5: Working with Namespaces

### Task 5.1: Create and Use Namespaces
```bash
# List all namespaces
kubectl get namespaces

# Create a new namespace
kubectl create namespace dev

# Create resources in specific namespace
kubectl apply -f nginx-pod.yaml -n dev

# List pods in specific namespace
kubectl get pods -n dev

# List pods in all namespaces
kubectl get pods --all-namespaces

# Set default namespace for context
kubectl config set-context --current --namespace=dev
```

### Task 5.2: Resource Quotas in Namespaces
Create `dev-quota.yaml`:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "10"
```

```bash
# Apply the quota
kubectl apply -f dev-quota.yaml

# View quotas
kubectl get resourcequota -n dev

# Describe the quota
kubectl describe resourcequota dev-quota -n dev
```

## Exercise 6: Labels and Selectors

### Task 6.1: Working with Labels
```bash
# Add a label to a pod
kubectl label pod nginx-pod environment=production

# View labels
kubectl get pods --show-labels

# Filter pods by label
kubectl get pods -l app=nginx
kubectl get pods -l environment=production

# Update a label
kubectl label pod nginx-pod environment=staging --overwrite

# Remove a label
kubectl label pod nginx-pod environment-
```

### Task 6.2: Using Selectors
```bash
# Equality-based selector
kubectl get pods -l app=nginx,tier=frontend

# Set-based selector
kubectl get pods -l 'environment in (production, staging)'
kubectl get pods -l 'tier,tier notin (backend)'
```

## Cleanup
```bash
# Delete all resources created in default namespace
kubectl delete deployment nginx-deployment
kubectl delete service nginx-service nginx-nodeport
kubectl delete pod nginx-pod multi-container-pod

# Delete namespace and all resources in it
kubectl delete namespace dev
```

## Challenge Exercise

Create a complete application stack with:
1. A namespace called "myapp"
2. A deployment with 3 replicas running nginx
3. A ClusterIP service exposing the deployment
4. A ResourceQuota limiting the namespace
5. All resources should have appropriate labels

## Verification Checklist

- [ ] Created and inspected pods
- [ ] Created multi-container pods
- [ ] Created and scaled deployments
- [ ] Performed rolling updates
- [ ] Created ClusterIP and NodePort services
- [ ] Created and used namespaces
- [ ] Applied resource quotas
- [ ] Used labels and selectors

## Additional Resources
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
