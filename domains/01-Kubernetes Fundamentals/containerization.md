# Containerization

## Overview

Container fundamentals, runtimes, and how containers work within Kubernetes.

## Key Topics

### Container Basics

- What are containers?
- Containers vs Virtual Machines
- Container images and registries
- Image layers and optimization
- Container lifecycle

### Container Runtimes

- **Container Runtime Interface (CRI)**
- **containerd**: Industry-standard container runtime
- **CRI-O**: Lightweight container runtime for Kubernetes
- **Docker**: Container platform (deprecated as runtime in K8s)
- Runtime comparison and use cases

### Container Images

- Image registries (Docker Hub, Harbor, etc.)
- Image naming and tagging
- Building container images
- Dockerfile best practices
- Multi-stage builds
- Image security scanning

### Container Configuration in Kubernetes

- Image pull policies
- Container commands and arguments
- Environment variables
- Volume mounts
- Resource requests and limits
- Security context

### Container Best Practices

- Use specific image tags (avoid :latest)
- Minimize image size
- Run as non-root user
- Use read-only root filesystems
- Implement health checks
- Follow the principle of least privilege

## Examples

### Basic Container in Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: nginx:1.21
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
    env:
    - name: ENVIRONMENT
      value: "production"
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

### Multi-Container Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container
spec:
  containers:
  - name: app
    image: myapp:1.0
  - name: sidecar
    image: logger:1.0
```

## Study Resources

- [Container Runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
- [Images](https://kubernetes.io/docs/concepts/containers/images/)
- [Container Environment](https://kubernetes.io/docs/concepts/containers/container-environment/)
- [Docker Documentation](https://docs.docker.com/)

## Key Points to Remember

- Containers package applications with their dependencies
- Kubernetes uses CRI-compatible runtimes (containerd, CRI-O)
- Images should be small, secure, and versioned
- Container configuration affects scheduling and security
- Multi-container pods share network and storage

## Hands-On Practice

- [Lab 04: Containerization](../../labs/01-kubernetes-fundamentals/lab-04-containerization.md) - Practical exercises covering container runtimes, image building, multi-container patterns, and init containers
