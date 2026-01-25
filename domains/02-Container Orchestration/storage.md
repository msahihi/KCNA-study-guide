# Storage

## Overview

Persistent storage, volumes, and storage classes in Kubernetes.

## Key Topics

### Storage Concepts

- Ephemeral vs Persistent storage
- Volume lifecycle
- Storage provisioning (static vs dynamic)
- Access modes
- Reclaim policies

### Volume Types

#### Ephemeral Volumes

- **emptyDir**: Temporary storage, lifecycle tied to pod
- **configMap**: Mount configuration data
- **secret**: Mount sensitive data
- **downwardAPI**: Expose pod metadata

#### Persistent Volumes

- **PersistentVolume (PV)**: Cluster-level storage resource
- **PersistentVolumeClaim (PVC)**: User request for storage
- **StorageClass**: Dynamic provisioning template

### Volume Plugins

- **hostPath**: Mount directory from node (dev/test only)
- **nfs**: Network File System
- **csi**: Container Storage Interface (modern approach)
- **Cloud providers**: AWS EBS, Azure Disk, GCE PD
- **cephfs**, **glusterfs**: Distributed storage systems

### Container Storage Interface (CSI)

- Standard interface for storage systems
- Plugin architecture
- Vendor-agnostic storage integration
- Dynamic provisioning support

### Access Modes

- **ReadWriteOnce (RWO)**: Single node read-write
- **ReadOnlyMany (ROX)**: Multiple nodes read-only
- **ReadWriteMany (RWX)**: Multiple nodes read-write
- **ReadWriteOncePod (RWOP)**: Single pod read-write (1.22+)

### Reclaim Policies

- **Retain**: Manual reclamation required
- **Delete**: Automatically delete storage
- **Recycle**: Basic scrub (deprecated)

### Storage Classes

- Define types of storage available
- Enable dynamic provisioning
- Configure parameters (IOPS, type, etc.)
- Set default storage class

## Examples

### EmptyDir Volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: cache
      mountPath: /cache
  volumes:
  - name: cache
    emptyDir: {}
```

### PersistentVolume and PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: manual
```

### Using PVC in Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-storage
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-data
```

### StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

### Dynamic Provisioning

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: fast
  resources:
    requests:
      storage: 20Gi
```

### ConfigMap as Volume

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  config.yaml: |
    setting1: value1
    setting2: value2
---
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: myapp
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-config
```

## Storage Best Practices

- Use PVCs instead of directly mounting PVs
- Choose appropriate access modes
- Set resource requests/limits
- Use StorageClasses for dynamic provisioning
- Consider backup and disaster recovery
- Monitor storage usage
- Use CSI drivers when available

## Common kubectl Commands

```bash
# List storage resources
kubectl get pv
kubectl get pvc
kubectl get storageclass

# Describe storage
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name>

# Check PVC status
kubectl get pvc -w  # watch for binding

# Delete PVC
kubectl delete pvc <pvc-name>
```

## Study Resources

- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [CSI Specification](https://github.com/container-storage-interface/spec)

## Key Points to Remember

- PVs are cluster resources, PVCs are namespace-scoped
- StorageClasses enable dynamic provisioning
- Access modes depend on storage backend capabilities
- Reclaim policy determines what happens when PVC is deleted
- CSI is the modern standard for storage plugins
- emptyDir is ephemeral and lost when pod is removed
- Choose access modes based on application requirements

## Hands-On Practice

- [Lab 04: Storage](../../labs/02-container-orchestration/lab-04-storage.md) - Practical exercises covering Volumes, PV/PVC, StorageClasses, and StatefulSets
