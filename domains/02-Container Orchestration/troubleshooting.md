# Troubleshooting

## Overview

Debugging techniques and tools for diagnosing issues in Kubernetes clusters.

## Key Topics

### Troubleshooting Methodology

1. Identify the problem
2. Gather information
3. Form a hypothesis
4. Test the hypothesis
5. Implement a solution
6. Verify the fix

### Common Issues

- Pod not starting (ImagePullBackOff, CrashLoopBackOff)
- Service connectivity problems
- Resource constraints (CPU, memory)
- Configuration errors
- Network policy blocking traffic
- Permission issues (RBAC)

### kubectl Debugging Commands

#### View Resource Status

```bash
# Get pods with wide output
kubectl get pods -o wide

# Describe pod for detailed info
kubectl describe pod <pod-name>

# Get events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check pod logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>  # for specific container
kubectl logs <pod-name> --previous  # previous container logs
```

#### Interactive Debugging

```bash
# Execute command in container
kubectl exec <pod-name> -- <command>

# Get interactive shell
kubectl exec -it <pod-name> -- /bin/bash

# Port forward for local access
kubectl port-forward <pod-name> 8080:80

# Copy files to/from container
kubectl cp <pod-name>:/path/to/file ./local-file
```

#### Resource Inspection

```bash
# Check resource usage
kubectl top nodes
kubectl top pods

# Get YAML of running resource
kubectl get pod <pod-name> -o yaml

# Check API resources
kubectl api-resources
```

### Pod Status and Conditions

#### Common Pod Statuses

- **Pending**: Waiting to be scheduled
- **Running**: Pod is running
- **Succeeded**: All containers terminated successfully
- **Failed**: At least one container failed
- **Unknown**: Cannot determine pod state

#### Common Container States

- **Waiting**: Container is waiting to start
- **Running**: Container is running
- **Terminated**: Container has finished

#### Common Error States

- **ImagePullBackOff**: Cannot pull container image
- **CrashLoopBackOff**: Container keeps crashing
- **ErrImagePull**: Error pulling image
- **RunContainerError**: Cannot run container
- **OOMKilled**: Out of memory

### Debugging Workflows

#### ImagePullBackOff

```bash
# Check pod description
kubectl describe pod <pod-name>

# Common causes:
# - Wrong image name/tag
# - Image doesn't exist
# - No access to private registry
# - Network issues
```

#### CrashLoopBackOff

```bash
# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Common causes:
# - Application error
# - Missing configuration
# - Health check failures
# - Insufficient resources
```

#### Service Not Reachable

```bash
# Check service
kubectl get svc <service-name>
kubectl describe svc <service-name>

# Check endpoints
kubectl get endpoints <service-name>

# Verify label selectors match pods
kubectl get pods --show-labels
```

### Network Troubleshooting

```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup <service-name>

# Test connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash
# Then inside: curl, ping, traceroute, etc.

# Check network policies
kubectl get networkpolicies
kubectl describe networkpolicy <policy-name>
```

### Resource Constraints

```bash
# Check node resources
kubectl describe nodes

# Check resource quotas
kubectl get resourcequota
kubectl describe resourcequota <quota-name>

# Check limit ranges
kubectl get limitrange
```

### Debugging Tools

#### Ephemeral Debug Containers

```bash
# Add debug container to running pod (K8s 1.23+)
kubectl debug <pod-name> -it --image=busybox
```

#### Debug Node

```bash
# Create debug pod on node
kubectl debug node/<node-name> -it --image=ubuntu
```

## Example Debug Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
spec:
  containers:
  - name: debug
    image: nicolaka/netshoot
    command: ['sh', '-c', 'sleep 3600']
```

## Study Resources

- [Troubleshoot Applications](https://kubernetes.io/docs/tasks/debug/debug-application/)
- [Debug Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
- [Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)
- [Troubleshoot Clusters](https://kubernetes.io/docs/tasks/debug/debug-cluster/)

## Key Points to Remember

- Always check logs first with `kubectl logs`
- Use `kubectl describe` for detailed resource information
- Check events for cluster-level issues
- Verify labels and selectors match
- Use debug containers for live troubleshooting
- Monitor resource usage with `kubectl top`
- Test connectivity with ephemeral pods

## Hands-On Practice

- [Lab 03: Troubleshooting](../../labs/02-container-orchestration/lab-03-troubleshooting.md) - Practical exercises covering debugging techniques, common issues, and systematic troubleshooting
