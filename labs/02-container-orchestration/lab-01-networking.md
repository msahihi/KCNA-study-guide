# Lab 01: Kubernetes Networking

## Objectives
By the end of this lab, you will be able to:
- Understand Kubernetes networking fundamentals and the CNI
- Work with different Service types (ClusterIP, NodePort, LoadBalancer)
- Configure and use Ingress controllers
- Implement Network Policies for traffic control
- Troubleshoot DNS resolution in Kubernetes

## Prerequisites
- Running Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured and working
- Basic understanding of networking concepts
- For Ingress: NGINX Ingress Controller installed

## Estimated Time
120 minutes

---

## Part 1: CNI (Container Network Interface) Basics

### Exercise 1.1: Explore CNI Configuration

**Check the CNI plugin in use:**

```bash
# List CNI plugins
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}'

# Check CNI configuration on node (minikube example)
minikube ssh "ls /etc/cni/net.d/"

# View CNI configuration
minikube ssh "cat /etc/cni/net.d/*.conf"
```

**Common CNI plugins:**
- Calico
- Flannel
- Weave Net
- Cilium
- Canal

**Inspect pod networking:**

```bash
# Create a test pod
kubectl run test-pod --image=nginx:1.25

# Get pod IP
kubectl get pod test-pod -o wide

# Check pod network namespace (on node)
minikube ssh "sudo ip netns list"
```

**Questions:**
1. What is the CNI's primary responsibility?
2. How does the CNI differ between different Kubernetes networking solutions?
3. What is the pod network CIDR in your cluster?

---

## Part 2: Kubernetes Services

### Exercise 2.1: ClusterIP Service (Default)

ClusterIP exposes the service on a cluster-internal IP.

**Create a deployment:**

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
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
        image: nginx:1.25
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "32Mi"
            cpu: "50m"
          limits:
            memory: "64Mi"
            cpu: "100m"
```

**Create ClusterIP Service:**

```yaml
# clusterip-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-clusterip
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    name: http
  sessionAffinity: None
```

**Deploy and test:**

```bash
kubectl apply -f nginx-deployment.yaml
kubectl apply -f clusterip-service.yaml

# View service details
kubectl get svc nginx-clusterip
kubectl describe svc nginx-clusterip

# Get endpoints
kubectl get endpoints nginx-clusterip

# Test from within cluster
kubectl run curl-test --image=curlimages/curl:8.5.0 -i --rm --restart=Never -- curl nginx-clusterip

# Check service DNS resolution
kubectl run -it --rm debug --image=busybox:1.36 --restart=Never -- nslookup nginx-clusterip
```

### Exercise 2.2: NodePort Service

NodePort exposes the service on each node's IP at a static port.

**Create NodePort Service:**

```yaml
# nodeport-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080  # Optional: Range 30000-32767
    name: http
```

**Deploy and test:**

```bash
kubectl apply -f nodeport-service.yaml

# Get service details
kubectl get svc nginx-nodeport

# Get node IP
kubectl get nodes -o wide

# Test access (minikube example)
minikube service nginx-nodeport --url

# Access via curl
curl $(minikube ip):30080

# Or use port-forward for testing
kubectl port-forward svc/nginx-nodeport 8080:80
# Then access: curl localhost:8080
```

### Exercise 2.3: LoadBalancer Service

LoadBalancer exposes the service externally using a cloud provider's load balancer.

**Create LoadBalancer Service:**

```yaml
# loadbalancer-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # AWS example
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    name: http
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

**Deploy and test:**

```bash
kubectl apply -f loadbalancer-service.yaml

# Watch for external IP to be assigned
kubectl get svc nginx-loadbalancer -w

# For minikube, use tunnel in separate terminal
minikube tunnel

# Test access
curl $(kubectl get svc nginx-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

### Exercise 2.4: Headless Service

Headless service for StatefulSets or direct pod access.

**Create Headless Service:**

```yaml
# headless-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
spec:
  clusterIP: None  # This makes it headless
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

**Deploy and test:**

```bash
kubectl apply -f headless-service.yaml

# Verify no ClusterIP assigned
kubectl get svc nginx-headless

# DNS returns individual pod IPs
kubectl run -it --rm debug --image=busybox:1.36 --restart=Never -- nslookup nginx-headless

# List all pod IPs
kubectl run -it --rm debug --image=tutum/dnsutils --restart=Never -- dig nginx-headless.default.svc.cluster.local
```

**Questions:**
1. When would you use ClusterIP vs. NodePort vs. LoadBalancer?
2. What are the port ranges for NodePort services?
3. How does a headless service differ from a regular service?

---

## Part 3: Ingress

### Exercise 3.1: Install NGINX Ingress Controller

**For minikube:**

```bash
minikube addons enable ingress

# Verify ingress controller
kubectl get pods -n ingress-nginx
```

**For other clusters:**

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Exercise 3.2: Basic Ingress

**Create two different applications:**

```yaml
# app1-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: hashicorp/http-echo:1.0
        args:
        - "-text=Application 1"
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: app1-service
spec:
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 5678
```

```yaml
# app2-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: hashicorp/http-echo:1.0
        args:
        - "-text=Application 2"
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: app2-service
spec:
  selector:
    app: app2
  ports:
  - port: 80
    targetPort: 5678
```

**Create Ingress with path-based routing:**

```yaml
# basic-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

**Deploy and test:**

```bash
kubectl apply -f app1-deployment.yaml
kubectl apply -f app2-deployment.yaml
kubectl apply -f basic-ingress.yaml

# Get ingress details
kubectl get ingress basic-ingress
kubectl describe ingress basic-ingress

# Add to /etc/hosts (get IP from ingress)
echo "$(kubectl get ingress basic-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}') myapp.local" | sudo tee -a /etc/hosts

# Or for minikube
echo "$(minikube ip) myapp.local" | sudo tee -a /etc/hosts

# Test routes
curl http://myapp.local/app1
curl http://myapp.local/app2
```

### Exercise 3.3: Name-based Virtual Hosting

**Create Ingress with host-based routing:**

```yaml
# host-based-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

**Deploy and test:**

```bash
kubectl apply -f host-based-ingress.yaml

# Add hosts to /etc/hosts
INGRESS_IP=$(kubectl get ingress host-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "$INGRESS_IP app1.example.com" | sudo tee -a /etc/hosts
echo "$INGRESS_IP app2.example.com" | sudo tee -a /etc/hosts

# Test
curl http://app1.example.com
curl http://app2.example.com
```

### Exercise 3.4: TLS/SSL with Ingress

**Create a self-signed certificate:**

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.local/O=myapp"

# Create Kubernetes secret
kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key
```

**Create TLS Ingress:**

```yaml
# tls-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.local
    secretName: myapp-tls
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
```

**Deploy and test:**

```bash
kubectl apply -f tls-ingress.yaml

# Test HTTPS (ignore cert warning for self-signed)
curl -k https://myapp.local

# Test HTTP redirect to HTTPS
curl -L http://myapp.local
```

---

## Part 4: Network Policies

### Exercise 4.1: Default Deny All Traffic

**Create a namespace for testing:**

```bash
kubectl create namespace netpol-test
```

**Deploy test applications:**

```yaml
# test-apps.yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: netpol-test
  labels:
    app: frontend
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx:1.25
---
apiVersion: v1
kind: Pod
metadata:
  name: backend
  namespace: netpol-test
  labels:
    app: backend
    tier: backend
spec:
  containers:
  - name: nginx
    image: nginx:1.25
---
apiVersion: v1
kind: Pod
metadata:
  name: database
  namespace: netpol-test
  labels:
    app: database
    tier: database
spec:
  containers:
  - name: postgres
    image: postgres:16-alpine
    env:
    - name: POSTGRES_PASSWORD
      value: password
```

**Apply pods:**

```bash
kubectl apply -f test-apps.yaml

# Test connectivity (should work initially)
kubectl exec -n netpol-test frontend -- curl -s http://backend
```

**Create default deny policy:**

```yaml
# deny-all-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: netpol-test
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**Apply and test:**

```bash
kubectl apply -f deny-all-policy.yaml

# Test connectivity (should fail now)
kubectl exec -n netpol-test frontend -- curl -m 5 http://backend
```

### Exercise 4.2: Allow Specific Traffic

**Allow frontend to backend:**

```yaml
# allow-frontend-to-backend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: netpol-test
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
```

**Allow backend to database:**

```yaml
# allow-backend-to-database.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
  namespace: netpol-test
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
```

**Allow DNS:**

```yaml
# allow-dns.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: netpol-test
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

**Apply and test:**

```bash
kubectl apply -f allow-frontend-to-backend.yaml
kubectl apply -f allow-backend-to-database.yaml
kubectl apply -f allow-dns.yaml

# Test allowed connections
kubectl exec -n netpol-test frontend -- curl -s http://backend

# Test denied connection (should fail)
kubectl exec -n netpol-test frontend -- curl -m 5 http://database:5432
```

### Exercise 4.3: Namespace-based Network Policy

**Create another namespace:**

```bash
kubectl create namespace external
kubectl label namespace external name=external

# Create pod in external namespace
kubectl run external-pod --image=nginx:1.25 -n external
```

**Allow traffic from specific namespace:**

```yaml
# allow-from-namespace.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-external-ns
  namespace: netpol-test
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: external
    ports:
    - protocol: TCP
      port: 80
```

**Apply and test:**

```bash
kubectl apply -f allow-from-namespace.yaml

# Test from external namespace (should work)
kubectl exec -n external external-pod -- curl -s http://backend.netpol-test
```

**Questions:**
1. What happens if no Network Policy is applied to a pod?
2. Can you have both allow and deny rules in the same policy?
3. How do Network Policies work with Services?

---

## Part 5: DNS in Kubernetes

### Exercise 5.1: DNS Resolution Testing

**Create test pods:**

```bash
kubectl run dnsutils --image=tutum/dnsutils --command -- sleep 3600
```

**Test service DNS:**

```bash
# Format: <service-name>.<namespace>.svc.cluster.local

# Test ClusterIP service
kubectl exec dnsutils -- nslookup nginx-clusterip

# Full FQDN
kubectl exec dnsutils -- nslookup nginx-clusterip.default.svc.cluster.local

# Test headless service
kubectl exec dnsutils -- nslookup nginx-headless

# Dig for more details
kubectl exec dnsutils -- dig nginx-clusterip.default.svc.cluster.local
```

**Test pod DNS:**

```bash
# Get pod IP
POD_IP=$(kubectl get pod -l app=nginx -o jsonpath='{.items[0].status.podIP}' | tr . -)

# Pod DNS format: <pod-ip>.<namespace>.pod.cluster.local
kubectl exec dnsutils -- nslookup ${POD_IP}.default.pod.cluster.local
```

**Check CoreDNS configuration:**

```bash
# View CoreDNS ConfigMap
kubectl get configmap coredns -n kube-system -o yaml

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### Exercise 5.2: Custom DNS Configuration

**Create pod with custom DNS:**

```yaml
# custom-dns-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-dns
spec:
  containers:
  - name: test
    image: busybox:1.36
    command: ['sh', '-c', 'sleep 3600']
  dnsPolicy: "None"
  dnsConfig:
    nameservers:
    - 8.8.8.8
    - 1.1.1.1
    searches:
    - default.svc.cluster.local
    - svc.cluster.local
    - cluster.local
    options:
    - name: ndots
      value: "5"
```

**Deploy and test:**

```bash
kubectl apply -f custom-dns-pod.yaml

# Check DNS configuration
kubectl exec custom-dns -- cat /etc/resolv.conf

# Test resolution
kubectl exec custom-dns -- nslookup google.com
```

---

## Verification Questions

1. **CNI:**
   - What is the pod network CIDR in your cluster?
   - How does CNI differ from Docker networking?
   - Name three popular CNI plugins.

2. **Services:**
   - What is the difference between ClusterIP and NodePort?
   - When would you use a headless service?
   - How does session affinity work?

3. **Ingress:**
   - What is the difference between Ingress and Service?
   - Can you have multiple Ingress controllers in one cluster?
   - How does TLS termination work with Ingress?

4. **Network Policies:**
   - Are Network Policies stateful or stateless?
   - What is the default behavior without any Network Policy?
   - Can Network Policies span multiple namespaces?

5. **DNS:**
   - What is the FQDN format for a Kubernetes service?
   - How does CoreDNS handle DNS queries?
   - What is the difference between dnsPolicy ClusterFirst and Default?

---

## Cleanup

```bash
# Delete deployments and services
kubectl delete deployment nginx-deploy app1 app2
kubectl delete svc nginx-clusterip nginx-nodeport nginx-loadbalancer nginx-headless app1-service app2-service
kubectl delete ingress basic-ingress host-ingress tls-ingress
kubectl delete secret myapp-tls

# Delete network policy test namespace
kubectl delete namespace netpol-test
kubectl delete namespace external

# Delete test pods
kubectl delete pod test-pod curl-test dnsutils custom-dns

# Remove /etc/hosts entries
sudo sed -i.bak '/myapp.local\|app1.example.com\|app2.example.com/d' /etc/hosts

# Clean up certificates
rm -f tls.key tls.crt
```

---

## Challenge Exercise

Create a complete microservices architecture with:

1. **Three-tier application:**
   - Frontend (nginx)
   - Backend API (any image)
   - Database (postgres)

2. **Networking requirements:**
   - ClusterIP for backend and database
   - NodePort or LoadBalancer for frontend
   - Ingress with TLS for external access

3. **Security requirements:**
   - Network Policies allowing only:
     - Frontend → Backend
     - Backend → Database
     - All pods → DNS
   - Deny all other traffic

4. **Additional requirements:**
   - Custom DNS configuration for one pod
   - Health checks for all services
   - Resource limits on all pods

**Deliverables:**
- All YAML manifests
- Test script showing connectivity
- Documentation of security model
- Diagram of network architecture

---

## Additional Resources

- [Kubernetes Networking Model](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [CNI Specification](https://github.com/containernetworking/cni)

---

## Key Takeaways

- Kubernetes networking is flat: all pods can communicate without NAT
- Services provide stable endpoints for dynamic pod IPs
- Ingress provides HTTP/HTTPS routing to services
- Network Policies control traffic flow at the pod level
- DNS is provided by CoreDNS and follows predictable patterns
- CNI plugins implement the pod networking model
