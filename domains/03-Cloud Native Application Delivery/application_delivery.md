# Application Delivery

## Overview

Modern deployment strategies, CI/CD practices, and GitOps principles for cloud-native applications.

## Key Topics

### Deployment Strategies

#### Rolling Update

- Default Kubernetes deployment strategy
- Gradually replace old pods with new ones
- Zero downtime deployments
- Configurable via maxSurge and maxUnavailable

#### Blue-Green Deployment

- Run two identical environments (blue and green)
- Switch traffic from blue to green atomically
- Easy rollback by switching back
- Requires double infrastructure

#### Canary Deployment

- Gradually roll out changes to subset of users
- Monitor metrics before full rollout
- Reduce risk of bad deployments
- Progressive delivery approach

#### Recreate

- Terminate all old pods before creating new ones
- Causes downtime
- Useful when running different versions simultaneously isn't possible

### Continuous Integration / Continuous Deployment (CI/CD)

#### CI/CD Concepts

- Continuous Integration: Automatically build and test code changes
- Continuous Delivery: Automatically deploy to staging
- Continuous Deployment: Automatically deploy to production
- Pipeline automation

#### Popular CI/CD Tools

- **Jenkins**: Open-source automation server
- **GitLab CI/CD**: Integrated with GitLab
- **GitHub Actions**: GitHub's CI/CD solution
- **Tekton**: Kubernetes-native CI/CD
- **Argo Workflows**: Container-native workflow engine
- **CircleCI**, **Travis CI**: Cloud-based CI/CD

### GitOps

#### GitOps Principles

1. Declarative configuration stored in Git
2. Git as single source of truth
3. Automated deployment from Git
4. Continuous reconciliation of desired and actual state

#### GitOps Benefits

- Version control for infrastructure
- Audit trail and rollback capability
- Declarative and reproducible deployments
- Enhanced security through Git access control
- Improved collaboration

#### GitOps Tools

- **Flux**: Kubernetes operator for GitOps
- **Argo CD**: Declarative GitOps CD for Kubernetes
- **Jenkins X**: CI/CD solution for Kubernetes with GitOps

### Application Packaging

#### Helm

- Package manager for Kubernetes
- Helm Charts: Reusable Kubernetes configurations
- Templating and parameterization
- Version management and rollback
- Repository system for sharing charts

#### Kustomize

- Native Kubernetes configuration management
- Overlay-based customization
- No templating, uses patches
- Built into kubectl

### Progressive Delivery

#### Feature Flags

- Toggle features on/off without deployment
- A/B testing
- Gradual feature rollout
- Quick rollback capability

#### Traffic Management

- Service meshes (Istio, Linkerd)
- Weighted routing
- Header-based routing
- Advanced traffic splitting

## Examples

### Rolling Update Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:v2
        ports:
        - containerPort: 8080
```

### Blue-Green with Services

```yaml
# Blue deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
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
      - name: myapp
        image: myapp:v1
---
# Green deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
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
      - name: myapp
        image: myapp:v2
---
# Service (switch selector to change active version)
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    version: green  # Switch between blue/green
  ports:
  - port: 80
    targetPort: 8080
```

### Basic Helm Chart Structure

```
mychart/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── templates/          # Kubernetes manifests templates
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── charts/            # Dependent charts
```

### Kustomize Structure

```
base/
├── kustomization.yaml
├── deployment.yaml
└── service.yaml

overlays/
├── dev/
│   ├── kustomization.yaml
│   └── patch.yaml
└── prod/
    ├── kustomization.yaml
    └── patch.yaml
```

## kubectl Commands for Deployments

```bash
# Create/update deployment
kubectl apply -f deployment.yaml

# Check rollout status
kubectl rollout status deployment/myapp

# View rollout history
kubectl rollout history deployment/myapp

# Rollback to previous version
kubectl rollout undo deployment/myapp

# Rollback to specific revision
kubectl rollout undo deployment/myapp --to-revision=2

# Pause/resume rollout
kubectl rollout pause deployment/myapp
kubectl rollout resume deployment/myapp

# Scale deployment
kubectl scale deployment/myapp --replicas=5

# Set image (trigger update)
kubectl set image deployment/myapp myapp=myapp:v2
```

## Study Resources

- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [GitOps Principles](https://opengitops.dev/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kustomize](https://kustomize.io/)
- [Argo CD](https://argo-cd.readthedocs.io/)
- [Flux](https://fluxcd.io/)

## Key Points to Remember

- Rolling updates are the default Kubernetes deployment strategy
- GitOps uses Git as the single source of truth
- Canary deployments reduce risk by gradual rollout
- Helm packages Kubernetes applications for reuse
- CI/CD automates the software delivery pipeline
- Progressive delivery enables safer releases
- Always have a rollback strategy

## Hands-On Practice

- [Lab 01: Application Delivery](../../labs/03-cloud-native-application-delivery/lab-01-application-delivery.md) - Practical exercises covering deployment strategies, Helm, Kustomize, and GitOps
