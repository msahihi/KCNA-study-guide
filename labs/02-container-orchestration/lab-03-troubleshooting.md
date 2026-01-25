# Lab 03: Kubernetes Troubleshooting

## Objectives
By the end of this lab, you will be able to:
- Use kubectl debug commands effectively
- Analyze logs and events to diagnose issues
- Troubleshoot common pod states (ImagePullBackOff, CrashLoopBackOff, Pending)
- Debug networking and DNS issues
- Use ephemeral containers for debugging
- Apply systematic troubleshooting methodologies

## Prerequisites
- Running Kubernetes cluster
- kubectl configured and working
- Basic understanding of Kubernetes resources
- Knowledge of Linux commands

## Estimated Time
90 minutes

---

## Part 1: Essential Troubleshooting Commands

### Exercise 1.1: Basic Inspection Commands

**Create a test deployment:**

```yaml
# test-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
```

**Deploy:**

```bash
kubectl apply -f test-deployment.yaml
```

**Essential inspection commands:**

```bash
# Get pods with more details
kubectl get pods -o wide

# Describe pod (most important troubleshooting command)
kubectl describe pod <pod-name>

# Get pod YAML
kubectl get pod <pod-name> -o yaml

# Get pod logs
kubectl logs <pod-name>

# Previous container logs (if crashed)
kubectl logs <pod-name> --previous

# Follow logs in real-time
kubectl logs <pod-name> -f

# Logs from specific container in multi-container pod
kubectl logs <pod-name> -c <container-name>

# Get events sorted by timestamp
kubectl get events --sort-by=.metadata.creationTimestamp

# Get events for specific pod
kubectl get events --field-selector involvedObject.name=<pod-name>
```

### Exercise 1.2: Resource Status Checks

**Check cluster resources:**

```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check resource usage
kubectl top nodes
kubectl top pods

# Check all resources in namespace
kubectl get all

# Check resource quotas
kubectl get resourcequota

# Check limit ranges
kubectl get limitrange
```

**Questions:**
1. What information does `kubectl describe` provide that `kubectl get` doesn't?
2. When would you use `--previous` with kubectl logs?
3. How do events help in troubleshooting?

---

## Part 2: Common Pod Issues

### Exercise 2.1: ImagePullBackOff

**Create pod with non-existent image:**

```yaml
# imagepull-error.yaml
apiVersion: v1
kind: Pod
metadata:
  name: imagepull-error
spec:
  containers:
  - name: app
    image: nginx:nonexistent-tag
```

**Deploy and troubleshoot:**

```bash
kubectl apply -f imagepull-error.yaml

# Check pod status
kubectl get pod imagepull-error

# Describe pod to see error
kubectl describe pod imagepull-error

# Check events
kubectl get events --field-selector involvedObject.name=imagepull-error
```

**Common causes:**
- Typo in image name or tag
- Image doesn't exist
- No access to private registry
- Missing imagePullSecrets

**Fix with correct image:**

```bash
kubectl set image pod/imagepull-error app=nginx:1.25
```

**Or create with private registry credentials:**

```yaml
# private-registry-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-registry-pod
spec:
  containers:
  - name: app
    image: myregistry.com/myapp:v1
  imagePullSecrets:
  - name: regcred
```

### Exercise 2.2: CrashLoopBackOff

**Create pod that crashes:**

```yaml
# crashloop-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: crashloop-pod
spec:
  containers:
  - name: crasher
    image: busybox:1.36
    command: ["sh", "-c", "echo Starting...; exit 1"]
```

**Deploy and troubleshoot:**

```bash
kubectl apply -f crashloop-pod.yaml

# Watch pod status
kubectl get pod crashloop-pod -w

# Check logs
kubectl logs crashloop-pod

# Check previous container logs
kubectl logs crashloop-pod --previous

# Describe for restart count
kubectl describe pod crashloop-pod | grep -A 5 "State\|Last State\|Restart Count"
```

**Common causes:**
- Application error/crash
- Missing environment variables
- Failed health checks
- Permission issues
- Missing dependencies

**Create pod with common crash scenario:**

```yaml
# missing-env-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: missing-env-pod
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c"]
    args:
    - |
      if [ -z "$REQUIRED_VAR" ]; then
        echo "ERROR: REQUIRED_VAR is not set"
        exit 1
      fi
      echo "Starting application..."
      sleep 3600
    # Missing env var will cause crash
```

**Fix by adding environment variable:**

```yaml
# fixed-env-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: fixed-env-pod
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c"]
    args:
    - |
      if [ -z "$REQUIRED_VAR" ]; then
        echo "ERROR: REQUIRED_VAR is not set"
        exit 1
      fi
      echo "Starting application with $REQUIRED_VAR"
      sleep 3600
    env:
    - name: REQUIRED_VAR
      value: "production"
```

### Exercise 2.3: Pending Pods

**Create pod with resource constraints:**

```yaml
# pending-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pending-pod
spec:
  containers:
  - name: app
    image: nginx:1.25
    resources:
      requests:
        memory: "1Ti"  # Unrealistic request
        cpu: "1000"
```

**Deploy and troubleshoot:**

```bash
kubectl apply -f pending-pod.yaml

# Check status
kubectl get pod pending-pod

# Describe to see scheduling issues
kubectl describe pod pending-pod

# Check scheduler events
kubectl get events | grep pending-pod
```

**Common causes:**
- Insufficient resources on nodes
- Node selector/affinity not matching
- Taints without tolerations
- Volume mount issues
- Resource quotas exceeded

**Create pod that can't be scheduled due to node selector:**

```yaml
# nodeselect-pending.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nodeselect-pending
spec:
  nodeSelector:
    disktype: ssd  # No node has this label
  containers:
  - name: nginx
    image: nginx:1.25
```

**Fix by removing or correcting node selector:**

```bash
# Label a node
kubectl label node <node-name> disktype=ssd

# Or edit pod to remove nodeSelector
kubectl delete pod nodeselect-pending
```

### Exercise 2.4: Pod Not Ready

**Create pod with failing readiness probe:**

```yaml
# notready-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: notready-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
    readinessProbe:
      httpGet:
        path: /healthz  # This endpoint doesn't exist
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
```

**Deploy and troubleshoot:**

```bash
kubectl apply -f notready-pod.yaml

# Check ready status
kubectl get pod notready-pod

# Describe to see probe failures
kubectl describe pod notready-pod | grep -A 10 "Readiness\|Events"

# Check container logs
kubectl logs notready-pod
```

**Fix readiness probe:**

```yaml
# fixed-ready-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: fixed-ready-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
    readinessProbe:
      httpGet:
        path: /  # Correct endpoint
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
```

**Questions:**
1. What's the difference between ImagePullBackOff and ErrImagePull?
2. How can you prevent CrashLoopBackOff during development?
3. What's the difference between readiness and liveness probes?

---

## Part 3: kubectl debug and Ephemeral Containers

### Exercise 3.1: Debug Running Pods

**Create a minimal pod without debugging tools:**

```yaml
# minimal-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: minimal-pod
spec:
  containers:
  - name: app
    image: gcr.io/distroless/static-debian11
    command: ["sleep", "3600"]
```

**Deploy:**

```bash
kubectl apply -f minimal-pod.yaml
```

**Debug with ephemeral container (Kubernetes 1.25+):**

```bash
# Add ephemeral debug container
kubectl debug minimal-pod -it --image=busybox:1.36 --target=app

# Or with different image
kubectl debug minimal-pod -it --image=ubuntu:22.04 -- bash
```

**Debug by creating copy of pod:**

```bash
# Create a copy with a different image
kubectl debug minimal-pod -it --copy-to=debug-pod --image=busybox:1.36 -- sh

# Create copy with shell access
kubectl debug minimal-pod -it --copy-to=debug-pod --container=app --image=busybox:1.36 -- sh
```

### Exercise 3.2: Debug Node Issues

**Debug node using privileged container:**

```bash
# Create debug pod on specific node
kubectl debug node/<node-name> -it --image=ubuntu:22.04

# Once inside, you have access to host filesystem at /host
chroot /host

# Check system logs
journalctl -u kubelet

# Check disk space
df -h

# Check kubelet status
systemctl status kubelet
```

### Exercise 3.3: Network Debugging

**Create network debugging pod:**

```yaml
# netshoot-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: netshoot
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot:latest
    command: ["sleep", "3600"]
```

**Deploy and use:**

```bash
kubectl apply -f netshoot-pod.yaml

# Network diagnostics
kubectl exec netshoot -- ping google.com
kubectl exec netshoot -- nslookup kubernetes.default
kubectl exec netshoot -- curl http://kubernetes.default
kubectl exec netshoot -- traceroute google.com
kubectl exec netshoot -- netstat -tulpn

# Test service connectivity
kubectl exec netshoot -- curl http://my-service.default.svc.cluster.local
```

**Questions:**
1. When should you use ephemeral containers vs. copying pods?
2. What security implications come with node debugging?
3. What tools should every network debug container include?

---

## Part 4: Service and DNS Troubleshooting

### Exercise 4.1: Service Connectivity Issues

**Create deployment and service:**

```yaml
# web-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web  # Must match pod labels
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

**Troubleshoot service:**

```bash
kubectl apply -f web-service.yaml

# Check service
kubectl get svc web-service
kubectl describe svc web-service

# Verify endpoints
kubectl get endpoints web-service

# If no endpoints, check:
# 1. Pod labels match service selector
kubectl get pods --show-labels | grep web

# 2. Pods are ready
kubectl get pods -l app=web

# 3. Port numbers match
kubectl get pods -l app=web -o jsonpath='{.items[*].spec.containers[*].ports[*].containerPort}'

# Test service from another pod
kubectl run curl-test --image=curlimages/curl:8.5.0 -i --rm --restart=Never -- \
  curl -v http://web-service
```

**Common service issues:**

```yaml
# Wrong selector (no endpoints)
apiVersion: v1
kind: Service
metadata:
  name: broken-service
spec:
  selector:
    app: wrong-label  # Doesn't match any pods
  ports:
  - port: 80
```

```yaml
# Wrong targetPort
apiVersion: v1
kind: Service
metadata:
  name: broken-targetport
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080  # But containers listen on 80
```

### Exercise 4.2: DNS Troubleshooting

**Test DNS resolution:**

```bash
# Create DNS debugging pod
kubectl run dnsutils --image=tutum/dnsutils --command -- sleep 3600

# Test service DNS
kubectl exec dnsutils -- nslookup web-service
kubectl exec dnsutils -- nslookup web-service.default
kubectl exec dnsutils -- nslookup web-service.default.svc.cluster.local

# Test external DNS
kubectl exec dnsutils -- nslookup google.com

# Check DNS configuration
kubectl exec dnsutils -- cat /etc/resolv.conf

# Detailed DNS query
kubectl exec dnsutils -- dig web-service.default.svc.cluster.local
```

**Check CoreDNS:**

```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Check CoreDNS ConfigMap
kubectl get configmap coredns -n kube-system -o yaml
```

**Common DNS issues:**

```bash
# Verify DNS service exists
kubectl get svc -n kube-system | grep dns

# Check if DNS pods are running
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS from problematic pod
kubectl exec <pod-name> -- cat /etc/resolv.conf
```

---

## Part 5: Application-Level Debugging

### Exercise 5.1: Debug Application Errors

**Create application with intentional errors:**

```yaml
# buggy-app.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  config.json: |
    {
      "database": {
        "host": "postgres-service",
        "port": 5432
      }
    }
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
        command: ["sh", "-c"]
        args:
        - |
          echo "Starting application..."
          cat /config/config.json
          echo "Connecting to database..."
          # This will fail - no postgres
          nc -z postgres-service 5432 || exit 1
        volumeMounts:
        - name: config
          mountPath: /config
      volumes:
      - name: config
        configMap:
          name: app-config
```

**Deploy and debug:**

```bash
kubectl apply -f buggy-app.yaml

# Check pod status
kubectl get pods -l app=buggy

# View logs
kubectl logs -l app=buggy

# Check configuration
kubectl exec deployment/buggy-app -- cat /config/config.json

# Verify connectivity
kubectl exec deployment/buggy-app -- nc -zv postgres-service 5432 || echo "Connection failed"
```

### Exercise 5.2: Debug with Verbose Logging

**Enable verbose logging:**

```yaml
# verbose-app.yaml
apiVersion: v1
kind: Pod
metadata:
  name: verbose-app
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c"]
    args:
    - |
      set -x  # Enable debug mode
      echo "Debug: Starting application"
      echo "Debug: Environment variables:"
      env | grep -v PASSWORD
      echo "Debug: Network interfaces:"
      ip addr
      echo "Debug: DNS configuration:"
      cat /etc/resolv.conf
      sleep 3600
    env:
    - name: DEBUG
      value: "true"
    - name: LOG_LEVEL
      value: "debug"
```

### Exercise 5.3: Resource Constraints Issues

**Create pod hitting resource limits:**

```yaml
# resource-limited-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-limited
spec:
  containers:
  - name: memory-hog
    image: polinux/stress:latest
    command: ["stress"]
    args:
    - "--vm"
    - "1"
    - "--vm-bytes"
    - "200M"
    - "--vm-hang"
    - "1"
    resources:
      requests:
        memory: "100Mi"
        cpu: "100m"
      limits:
        memory: "150Mi"  # Will be OOMKilled
        cpu: "200m"
```

**Monitor and debug:**

```bash
kubectl apply -f resource-limited-pod.yaml

# Watch pod status
kubectl get pod resource-limited -w

# Check events for OOMKilled
kubectl describe pod resource-limited | grep -A 5 "State\|Last State"

# Check resource usage
kubectl top pod resource-limited
```

---

## Part 6: Systematic Troubleshooting Process

### Exercise 6.1: Complete Troubleshooting Workflow

**Systematic approach:**

```bash
# 1. Identify the problem
kubectl get pods
kubectl get events --sort-by=.metadata.creationTimestamp

# 2. Gather information
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get pod <pod-name> -o yaml

# 3. Check dependencies
kubectl get svc
kubectl get endpoints
kubectl get pvc
kubectl get configmap
kubectl get secret

# 4. Test connectivity
kubectl run test --image=busybox:1.36 -it --rm -- sh
# Inside: ping, wget, nc, nslookup

# 5. Check resources
kubectl top nodes
kubectl top pods
kubectl describe nodes

# 6. Review configuration
kubectl get pod <pod-name> -o json | jq '.spec.containers[].env'
kubectl exec <pod-name> -- env

# 7. Check RBAC
kubectl auth can-i --list --as=system:serviceaccount:default:default
```

### Exercise 6.2: Debugging Checklist

**Create debugging script:**

```bash
#!/bin/bash
# debug-pod.sh

POD_NAME=$1
NAMESPACE=${2:-default}

echo "=== Pod Status ==="
kubectl get pod $POD_NAME -n $NAMESPACE

echo -e "\n=== Pod Details ==="
kubectl describe pod $POD_NAME -n $NAMESPACE

echo -e "\n=== Pod Logs ==="
kubectl logs $POD_NAME -n $NAMESPACE --tail=50

echo -e "\n=== Previous Logs (if crashed) ==="
kubectl logs $POD_NAME -n $NAMESPACE --previous --tail=50 2>/dev/null || echo "No previous logs"

echo -e "\n=== Events ==="
kubectl get events -n $NAMESPACE --field-selector involvedObject.name=$POD_NAME

echo -e "\n=== Resource Usage ==="
kubectl top pod $POD_NAME -n $NAMESPACE 2>/dev/null || echo "Metrics not available"

echo -e "\n=== Service Endpoints ==="
kubectl get endpoints -n $NAMESPACE

echo -e "\n=== Network Policies ==="
kubectl get networkpolicies -n $NAMESPACE
```

**Make executable and use:**

```bash
chmod +x debug-pod.sh
./debug-pod.sh <pod-name> <namespace>
```

**Questions:**
1. What are the first three commands you should run when troubleshooting a pod?
2. How do you determine if an issue is application-level or infrastructure-level?
3. When should you escalate to checking node-level issues?

---

## Verification Questions

1. **Pod States:**
   - What causes ImagePullBackOff vs ErrImagePull?
   - How do you access logs from a crashed container?
   - What's the difference between Pending and ContainerCreating?

2. **Debugging Tools:**
   - When should you use ephemeral containers?
   - What's the purpose of kubectl debug node?
   - How do you debug a distroless container?

3. **Services & DNS:**
   - How do you verify service endpoints?
   - What's the full DNS name format for a service?
   - Where does CoreDNS configuration come from?

4. **Resource Issues:**
   - What happens when a pod exceeds memory limits?
   - How do you identify resource constraints?
   - What's the difference between requests and limits?

5. **Best Practices:**
   - What information should you gather first?
   - How do you isolate networking vs application issues?
   - When should you check RBAC permissions?

---

## Cleanup

```bash
# Delete test pods
kubectl delete pod imagepull-error crashloop-pod missing-env-pod fixed-env-pod pending-pod nodeselect-pending notready-pod fixed-ready-pod minimal-pod netshoot dnsutils verbose-app resource-limited

# Delete deployments
kubectl delete deployment test-app buggy-app web

# Delete services
kubectl delete svc web-service broken-service broken-targetport

# Delete configmaps
kubectl delete configmap app-config

# Remove debug pods
kubectl delete pod --field-selector=status.phase==Succeeded
kubectl delete pod --field-selector=status.phase==Failed
```

---

## Challenge Exercise

Create a broken multi-tier application and systematically troubleshoot it:

1. **Deploy a broken application** with the following intentional issues:
   - Frontend: Wrong service selector
   - Backend: CrashLoopBackOff due to missing environment variable
   - Database: ImagePullBackOff with wrong image tag
   - Network Policy blocking required traffic

2. **Create a troubleshooting document** showing:
   - Symptoms observed
   - Commands used to diagnose
   - Root cause identified
   - Fix applied
   - Verification of fix

3. **Requirements:**
   - Document each step with commands and output
   - Create a flowchart of your troubleshooting process
   - List lessons learned
   - Provide a "working" version after fixes

**Deliverables:**
- Broken application YAML manifests
- Troubleshooting documentation
- Fixed application YAML manifests
- Debugging script used
- Flowchart of troubleshooting process

---

## Additional Resources

- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [kubectl debug Documentation](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)
- [Troubleshooting Applications](https://kubernetes.io/docs/tasks/debug/debug-application/)
- [Troubleshooting Clusters](https://kubernetes.io/docs/tasks/debug/debug-cluster/)
- [Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)

---

## Key Takeaways

- Always start with `kubectl describe` and `kubectl logs`
- Events provide crucial information about scheduling and runtime issues
- Use ephemeral containers for debugging minimal/distroless images
- Service issues often relate to label selectors and endpoints
- DNS problems can be isolated by testing with nslookup/dig
- Resource constraints manifest as OOMKilled or throttling
- Systematic troubleshooting prevents missing important clues
- Understanding pod lifecycle states accelerates diagnosis
