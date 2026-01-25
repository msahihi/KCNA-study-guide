# Lab 01: Cloud Native Application Delivery

## Objectives

By the end of this lab, you will be able to:

- Implement various deployment strategies (Rolling Update, Blue-Green, Canary)
- Use Helm for package management
- Understand GitOps principles and practices
- Manage application configurations across environments
- Implement CI/CD best practices for Kubernetes

## Prerequisites

- Running Kubernetes cluster
- kubectl configured and working
- Helm 3 installed
- Git installed
- Basic understanding of deployments

## Estimated Time

120 minutes

---

## Part 1: Deployment Strategies

### Exercise 1.1: Rolling Update (Default Strategy)

**Create initial deployment:**

```yaml
# rolling-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-app
  labels:
    app: rolling
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods over desired count
      maxUnavailable: 1   # Max pods unavailable during update
  selector:
    matchLabels:
      app: rolling
  template:
    metadata:
      labels:
        app: rolling
        version: v1
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo:1.0
        args:
        - "-text=Version 1"
        ports:
        - containerPort: 5678
        readinessProbe:
          httpGet:
            path: /
            port: 5678
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: rolling-service
spec:
  selector:
    app: rolling
  ports:
  - port: 80
    targetPort: 5678
```

**Deploy and update:**

```bash
kubectl apply -f rolling-deployment.yaml

# Verify deployment
kubectl get deployment rolling-app
kubectl get pods -l app=rolling

# Watch the rolling update in action
kubectl apply -f rolling-deployment.yaml && kubectl rollout status deployment/rolling-app -w

# Update to version 2
kubectl set image deployment/rolling-app app=hashicorp/http-echo:latest
kubectl set env deployment/rolling-app app=-text="Version 2"

# Watch rolling update
kubectl rollout status deployment/rolling-app

# Check rollout history
kubectl rollout history deployment/rolling-app

# Rollback if needed
kubectl rollout undo deployment/rolling-app
```

**Test during update:**

```bash
# In one terminal, watch pods
kubectl get pods -l app=rolling -w

# In another terminal, continuously test service
while true; do
  kubectl run curl-test --image=curlimages/curl:8.5.0 --rm -i --restart=Never -- \
    curl -s rolling-service
  sleep 1
done
```

### Exercise 1.2: Blue-Green Deployment

**Create blue deployment (v1):**

```yaml
# blue-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
  labels:
    app: myapp
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo:1.0
        args:
        - "-text=Blue Version (v1)"
        ports:
        - containerPort: 5678
        readinessProbe:
          httpGet:
            path: /
            port: 5678
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Create green deployment (v2):**

```yaml
# green-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
  labels:
    app: myapp
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo:1.0
        args:
        - "-text=Green Version (v2)"
        ports:
        - containerPort: 5678
        readinessProbe:
          httpGet:
            path: /
            port: 5678
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Create service pointing to blue:**

```yaml
# bluegreen-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
    version: blue  # Initially points to blue
  ports:
  - port: 80
    targetPort: 5678
```

**Deploy and switch:**

```bash
# Deploy blue (v1)
kubectl apply -f blue-deployment.yaml
kubectl apply -f bluegreen-service.yaml

# Test blue version
kubectl run curl-test --image=curlimages/curl:8.5.0 --rm -i --restart=Never -- \
  curl myapp-service

# Deploy green (v2) in background
kubectl apply -f green-deployment.yaml

# Verify green is ready
kubectl wait --for=condition=available deployment/app-green --timeout=60s

# Test green directly (before switching)
kubectl run curl-test --image=curlimages/curl:8.5.0 --rm -i --restart=Never -- \
  curl app-green-service  # Need to create this service for testing

# Switch traffic to green (instant cutover)
kubectl patch service myapp-service -p '{"spec":{"selector":{"version":"green"}}}'

# Test - should now show green
kubectl run curl-test --image=curlimages/curl:8.5.0 --rm -i --restart=Never -- \
  curl myapp-service

# Rollback to blue if needed
kubectl patch service myapp-service -p '{"spec":{"selector":{"version":"blue"}}}'

# After confirming green works, delete blue
kubectl delete deployment app-blue
```

### Exercise 1.3: Canary Deployment

**Create stable deployment:**

```yaml
# canary-stable.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-stable
  labels:
    app: canary-app
spec:
  replicas: 9  # 90% of traffic
  selector:
    matchLabels:
      app: canary-app
      version: stable
  template:
    metadata:
      labels:
        app: canary-app
        version: stable
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo:1.0
        args:
        - "-text=Stable Version"
        ports:
        - containerPort: 5678
```

**Create canary deployment:**

```yaml
# canary-new.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary
  labels:
    app: canary-app
spec:
  replicas: 1  # 10% of traffic
  selector:
    matchLabels:
      app: canary-app
      version: canary
  template:
    metadata:
      labels:
        app: canary-app
        version: canary
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo:1.0
        args:
        - "-text=Canary Version (NEW)"
        ports:
        - containerPort: 5678
```

**Create service (targets both):**

```yaml
# canary-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: canary-service
spec:
  selector:
    app: canary-app  # Targets both stable and canary
  ports:
  - port: 80
    targetPort: 5678
```

**Deploy and test:**

```bash
# Deploy stable version
kubectl apply -f canary-stable.yaml
kubectl apply -f canary-service.yaml

# Deploy canary (10% traffic)
kubectl apply -f canary-new.yaml

# Test distribution (run multiple times)
for i in {1..20}; do
  kubectl run curl-test-$i --image=curlimages/curl:8.5.0 --rm -i --restart=Never -- \
    curl -s canary-service
done
# Should see mostly "Stable" with occasional "Canary"

# Gradually increase canary
kubectl scale deployment app-canary --replicas=3  # 25% traffic
kubectl scale deployment app-stable --replicas=7

# Monitor metrics/errors for canary

# If canary successful, promote to 100%
kubectl scale deployment app-canary --replicas=10
kubectl scale deployment app-stable --replicas=0

# Eventually delete old stable
kubectl delete deployment app-stable

# If canary fails, rollback
kubectl scale deployment app-canary --replicas=0
```

**Questions:**

1. What are the advantages of blue-green vs rolling update?
2. When would you use canary deployment?
3. How do you automate canary analysis?

---

## Part 2: Helm Basics

### Exercise 2.1: Install Helm and Add Repositories

**Install Helm (if not already installed):**

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
```

**Add Helm repositories:**

```bash
# Add bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Add stable repository
helm repo add stable https://charts.helm.sh/stable

# Update repositories
helm repo update

# List repositories
helm repo list

# Search for charts
helm search repo nginx
helm search repo postgres
```

### Exercise 2.2: Install Application with Helm

**Install NGINX:**

```bash
# Install NGINX with default values
helm install my-nginx bitnami/nginx

# Check installation
helm list
kubectl get all -l app.kubernetes.io/instance=my-nginx

# Get release status
helm status my-nginx

# Get release values
helm get values my-nginx

# Get all values (including defaults)
helm get values my-nginx --all
```

**Install with custom values:**

```bash
# Create values file
cat > custom-values.yaml <<EOF
replicaCount: 3
service:
  type: NodePort
  nodePorts:
    http: 30080
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
EOF

# Install with custom values
helm install my-custom-nginx bitnami/nginx -f custom-values.yaml

# Or override specific values via command line
helm install my-nginx bitnami/nginx \
  --set replicaCount=3 \
  --set service.type=NodePort
```

### Exercise 2.3: Create Your Own Helm Chart

**Create chart structure:**

```bash
# Create new chart
helm create myapp

# View structure
tree myapp/
```

**Customize chart values (myapp/values.YAML):**

```yaml
replicaCount: 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.25"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false

resources:
  limits:
    cpu: 200m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 64Mi

autoscaling:
  enabled: false
```

**Edit deployment template (myapp/templates/deployment.YAML):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "myapp.fullname" . }}
  labels:
    {{- include "myapp.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "myapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "myapp.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
```

**Install your chart:**

```bash
# Lint chart
helm lint myapp/

# Dry run (test without installing)
helm install myapp ./myapp --dry-run --debug

# Install chart
helm install myapp ./myapp

# Verify
kubectl get all -l app.kubernetes.io/instance=myapp
```

### Exercise 2.4: Upgrade and Rollback

**Upgrade release:**

```bash
# Update values
cat > new-values.yaml <<EOF
replicaCount: 5
image:
  tag: "1.26"
EOF

# Upgrade release
helm upgrade myapp ./myapp -f new-values.yaml

# Check revision history
helm history myapp

# Check status
helm status myapp
```

**Rollback release:**

```bash
# Rollback to previous revision
helm rollback myapp

# Rollback to specific revision
helm rollback myapp 1

# Verify
helm history myapp
```

**Uninstall release:**

```bash
# Uninstall but keep history
helm uninstall myapp --keep-history

# Uninstall completely
helm uninstall myapp

# List uninstalled releases
helm list --uninstalled
```

**Questions:**

1. What is the difference between Helm install and Helm upgrade --install?
2. How does Helm track release history?
3. What are Helm hooks and when would you use them?

---

## Part 3: GitOps Principles

### Exercise 3.1: Understanding GitOps

**GitOps Core Principles:**

1. Declarative configuration stored in Git
2. Git as single source of truth
3. Automated deployment from Git
4. Continuous reconciliation

**Create Git repository structure:**

```bash
mkdir -p gitops-demo/{base,overlays/{dev,staging,prod}}
cd gitops-demo

# Initialize Git
git init

# Create base manifests
cat > base/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
EOF

cat > base/service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 80
EOF

cat > base/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml
EOF
```

**Create environment overlays:**

```bash
# Development overlay
cat > overlays/dev/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: dev

bases:
- ../../base

patchesStrategicMerge:
- deployment-patch.yaml

commonLabels:
  environment: dev
EOF

cat > overlays/dev/deployment-patch.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: app
        env:
        - name: ENVIRONMENT
          value: "development"
EOF

# Production overlay
cat > overlays/prod/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: prod

bases:
- ../../base

patchesStrategicMerge:
- deployment-patch.yaml

commonLabels:
  environment: prod
EOF

cat > overlays/prod/deployment-patch.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: app
        env:
        - name: ENVIRONMENT
          value: "production"
        resources:
          requests:
            memory: "128Mi"
            cpu: "200m"
          limits:
            memory: "256Mi"
            cpu: "500m"
EOF
```

**Deploy with Kustomize:**

```bash
# Create namespaces
kubectl create namespace dev
kubectl create namespace prod

# View rendered manifests
kubectl kustomize overlays/dev
kubectl kustomize overlays/prod

# Deploy to dev
kubectl apply -k overlays/dev

# Deploy to prod
kubectl apply -k overlays/prod

# Verify
kubectl get all -n dev
kubectl get all -n prod
```

### Exercise 3.2: GitOps Workflow Simulation

**Simulate GitOps workflow:**

```bash
# 1. Developer makes change
cat > base/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v2  # New label
    spec:
      containers:
      - name: app
        image: nginx:1.26  # Updated version
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
EOF

# 2. Commit to Git
git add .
git commit -m "Update nginx to v1.26"

# 3. GitOps tool (ArgoCD/Flux) detects change and applies
kubectl apply -k overlays/dev
kubectl apply -k overlays/prod

# 4. Verify deployment
kubectl rollout status deployment/myapp -n dev
kubectl get pods -n dev -l app=myapp --show-labels
```

### Exercise 3.3: Configuration Management

**Separate config from code:**

```bash
# Create ConfigMap in base
cat > base/configmap.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  app.conf: |
    server {
      listen 80;
      server_name localhost;
      location / {
        root /usr/share/nginx/html;
        index index.html;
      }
    }
EOF

# Update kustomization
cat > base/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml
- configmap.yaml
EOF

# Update deployment to use ConfigMap
cat >> overlays/dev/deployment-patch.yaml <<EOF
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: config
        configMap:
          name: myapp-config
EOF
```

**Questions:**

1. What are the benefits of GitOps over traditional deployment methods?
2. How do you handle secrets in GitOps?
3. What happens if manual changes are made to the cluster in GitOps?

---

## Part 4: Advanced Deployment Patterns

### Exercise 4.1: Progressive Delivery with Flagger (Conceptual)

**Install Flagger (optional - for demo):**

```bash
# Add Flagger Helm repository
helm repo add flagger https://flagger.app

# Install Flagger
kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml

# Create canary resource (example)
cat > canary.yaml <<EOF
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp
  namespace: default
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
EOF
```

### Exercise 4.2: Feature Flags

**Implement simple feature flag:**

```yaml
# feature-flag-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
data:
  features.json: |
    {
      "new_ui": false,
      "beta_feature": true,
      "experimental": false
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-flags
spec:
  replicas: 2
  selector:
    matchLabels:
      app: feature-app
  template:
    metadata:
      labels:
        app: feature-app
    spec:
      containers:
      - name: app
        image: nginx:1.25
        volumeMounts:
        - name: feature-flags
          mountPath: /etc/features
        env:
        - name: FEATURE_FLAGS_PATH
          value: "/etc/features/features.json"
      volumes:
      - name: feature-flags
        configMap:
          name: feature-flags
```

---

## Verification Questions

1. **Deployment Strategies:**
   - When is zero-downtime guaranteed with rolling updates?
   - What are the resource implications of blue-green deployment?
   - How do you determine canary percentage?

2. **Helm:**
   - What is the difference between Helm 2 and Helm 3?
   - How does Helm manage releases?
   - What are Helm hooks?

3. **GitOps:**
   - What tools implement GitOps (ArgoCD, Flux)?
   - How do you handle drift in GitOps?
   - How are secrets managed in GitOps?

4. **Best Practices:**
   - How do you test deployments before production?
   - What metrics should you monitor during deployments?
   - How do you implement automated rollback?

---

## Cleanup

```bash
# Delete deployments
kubectl delete deployment rolling-app app-blue app-green app-stable app-canary

# Delete services
kubectl delete service rolling-service myapp-service canary-service

# Uninstall Helm releases
helm uninstall my-nginx my-custom-nginx myapp

# Delete GitOps resources
kubectl delete -k overlays/dev
kubectl delete -k overlays/prod
kubectl delete namespace dev prod

# Clean up files
cd ..
rm -rf gitops-demo custom-values.yaml new-values.yaml
```

---

## Challenge Exercise

Create a complete CI/CD pipeline with:

1. **Multi-environment setup:**
   - Dev, Staging, Production
   - Different configurations per environment
   - Progressive promotion (dev → staging → prod)

2. **Deployment strategy:**
   - Rolling update in dev
   - Canary in staging
   - Blue-green in production

3. **Helm chart:**
   - Parameterized for all environments
   - Includes all necessary resources
   - Proper RBAC configuration

4. **GitOps structure:**
   - Git repository with all manifests
   - Kustomize overlays for environments
   - Documentation for deployment process

5. **Monitoring:**
   - Health checks for all deployments
   - Metrics collection
   - Automated rollback on failures

**Deliverables:**

- Git repository with all manifests
- Helm chart
- Deployment scripts
- Rollback procedures
- Monitoring configuration
- Complete documentation

---

## Additional Resources

- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Helm Documentation](https://helm.sh/docs/)
- [GitOps Principles](https://www.gitops.tech/)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [Flux](https://fluxcd.io/)
- [Flagger](https://flagger.app/)

---

## Key Takeaways

- Rolling updates provide zero-downtime deployments
- Blue-green enables instant rollback
- Canary reduces risk with gradual rollout
- Helm simplifies package management
- GitOps ensures declarative, version-controlled deployments
- Proper health checks are critical for all strategies
- Monitoring and observability enable safe deployments
- Automated rollback prevents extended outages
