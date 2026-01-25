# Networking

## Overview

Container networking, service discovery, and network policies in Kubernetes.

## Key Topics

### Kubernetes Networking Model

- Every pod gets its own IP address
- Pods can communicate without NAT
- Agents on a node can communicate with all pods
- Network plugins (CNI)

### Container Network Interface (CNI)

- CNI specification and plugins
- Popular CNI plugins:
  - Calico
  - Flannel
  - Weave Net
  - Cilium
  - Canal

### Services

- **ClusterIP**: Internal cluster communication (default)
- **NodePort**: Expose service on each node's IP at a static port
- **LoadBalancer**: Expose service via cloud provider's load balancer
- **ExternalName**: Map service to external DNS name
- **Headless Services**: Direct pod-to-pod communication

### Service Discovery

- DNS in Kubernetes
- Environment variables
- Service endpoints

### Ingress

- HTTP/HTTPS routing to services
- Ingress controllers (nginx, traefik, HAProxy)
- Path-based and host-based routing
- TLS/SSL termination

### Network Policies

- Control traffic flow between pods
- Ingress and egress rules
- Label-based pod selection
- Namespace isolation

## Examples

### ClusterIP Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
```

### Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-frontend
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### Ingress Resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

## Study Resources

- [Kubernetes Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

## Key Points to Remember

- Pods get unique IPs within the cluster
- Services provide stable networking endpoints
- Network policies are enforced by CNI plugins
- Ingress provides external HTTP/HTTPS access
- ClusterIP is for internal communication only

## Hands-On Practice

- [Lab 01: Networking](../../labs/02-container-orchestration/lab-01-networking.md) - Practical exercises covering CNI plugins, Services, Ingress, and Network Policies
