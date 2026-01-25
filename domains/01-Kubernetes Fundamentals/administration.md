# Administration

## Overview
Day-to-day management and operational tasks for Kubernetes clusters.

## Key Topics

### Cluster Management
- Cluster setup and configuration
- Node management
- Cluster upgrades
- Backup and restore strategies

### kubectl Commands
- Resource creation and management
- Viewing cluster state
- Debugging and troubleshooting
- Configuration management

### Configuration Management
- ConfigMaps: Store configuration data
- Secrets: Store sensitive information
- Environment variables
- Volume mounts for configuration

### Resource Management
- Resource Requests and Limits
  - CPU allocation
  - Memory allocation
- Resource Quotas
- LimitRanges

### Access Control
- RBAC (Role-Based Access Control)
  - Roles and ClusterRoles
  - RoleBindings and ClusterRoleBindings
- Service Accounts
- Authentication and Authorization

## Common kubectl Commands

```bash
# Get cluster info
kubectl cluster-info
kubectl get nodes

# Manage resources
kubectl get pods -A
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Apply configurations
kubectl apply -f <file.yaml>
kubectl delete -f <file.yaml>

# Scale applications
kubectl scale deployment <name> --replicas=3
```

## Study Resources
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Managing Resources](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
- [Configure Pods and Containers](https://kubernetes.io/docs/tasks/configure-pod-container/)

## Key Points to Remember
- Use kubectl for all cluster interactions
- ConfigMaps for non-sensitive data, Secrets for sensitive data
- Resource limits prevent resource exhaustion
- RBAC provides fine-grained access control

## Hands-On Practice
- [Lab 02: Administration](../../labs/01-kubernetes-fundamentals/lab-02-administration.md) - Practical exercises covering kubectl, ConfigMaps, Secrets, RBAC, and resource management
