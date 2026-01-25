# Lab 04: Kubernetes Storage

## Objectives

By the end of this lab, you will be able to:

- Understand different volume types in Kubernetes
- Work with PersistentVolumes (PV) and PersistentVolumeClaims (PVC)
- Configure StorageClasses for dynamic provisioning
- Implement stateful applications with StatefulSets
- Use ConfigMaps and Secrets as volumes
- Apply storage best practices

## Prerequisites

- Running Kubernetes cluster
- kubectl configured and working
- Basic understanding of storage concepts
- Cluster with storage provisioner (or local storage)

## Estimated Time

90 minutes

---

## Part 1: Volume Types

### Exercise 1.1: EmptyDir Volume

EmptyDir is created when a pod is assigned to a node and exists as long as the pod runs.

**Create pod with emptyDir:**

```yaml
# emptydir-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-pod
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c"]
    args:
    - |
      while true; do
        echo "$(date): Writing to shared volume" >> /data/logs.txt
        sleep 5
      done
    volumeMounts:
    - name: shared-data
      mountPath: /data

  - name: reader
    image: busybox:1.36
    command: ["sh", "-c"]
    args:
    - |
      while true; do
        if [ -f /data/logs.txt ]; then
          echo "=== Latest logs ==="
          tail -5 /data/logs.txt
        fi
        sleep 10
      done
    volumeMounts:
    - name: shared-data
      mountPath: /data
      readOnly: true

  volumes:
  - name: shared-data
    emptyDir: {}
```

**Deploy and test:**

```bash
kubectl apply -f emptydir-pod.yaml

# Check writer logs
kubectl logs emptydir-pod -c writer

# Check reader logs
kubectl logs emptydir-pod -c reader -f

# Verify data is shared
kubectl exec emptydir-pod -c reader -- cat /data/logs.txt
```

### Exercise 1.2: EmptyDir with Size Limit and Memory

**Create emptyDir with constraints:**

```yaml
# emptydir-advanced.yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-advanced
spec:
  containers:
  - name: app
    image: nginx:1.25
    volumeMounts:
    - name: cache
      mountPath: /cache
    - name: memory-vol
      mountPath: /memory

  volumes:
  # EmptyDir with size limit
  - name: cache
    emptyDir:
      sizeLimit: 100Mi

  # EmptyDir in memory (tmpfs)
  - name: memory-vol
    emptyDir:
      medium: Memory
      sizeLimit: 50Mi
```

**Deploy and test:**

```bash
kubectl apply -f emptydir-advanced.yaml

# Check mounted volumes
kubectl exec emptydir-advanced -- df -h | grep -E "cache|memory"
```

### Exercise 1.3: HostPath Volume

HostPath mounts a file or directory from the host node's filesystem.

**Warning:** Use hostPath only for special use cases (DaemonSets, node monitoring).

```yaml
# hostpath-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-pod
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "ls -la /host-data && sleep 3600"]
    volumeMounts:
    - name: host-volume
      mountPath: /host-data
    securityContext:
      privileged: true

  volumes:
  - name: host-volume
    hostPath:
      path: /var/log  # Host path
      type: Directory
```

**Deploy and test:**

```bash
kubectl apply -f hostpath-pod.yaml

# View host logs from container
kubectl exec hostpath-pod -- ls -la /host-data
```

**Questions:**

1. When is data in an emptyDir deleted?
2. What are the security implications of hostPath?
3. When would you use emptyDir with medium: Memory?

---

## Part 2: ConfigMaps and Secrets as Volumes

### Exercise 2.1: ConfigMap as Volume

**Create ConfigMap:**

```yaml
# nginx-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    events {
      worker_connections 1024;
    }
    http {
      server {
        listen 8080;
        location / {
          return 200 "Hello from ConfigMap!\n";
          add_header Content-Type text/plain;
        }
        location /health {
          return 200 "OK\n";
          add_header Content-Type text/plain;
        }
      }
    }
  index.html: |
    <html>
    <body>
      <h1>Configured via ConfigMap</h1>
    </body>
    </html>
```

**Use ConfigMap in Pod:**

```yaml
# configmap-volume-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-volume-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 8080
    volumeMounts:
    - name: config-volume
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
    - name: config-volume
      mountPath: /usr/share/nginx/html/index.html
      subPath: index.html

  volumes:
  - name: config-volume
    configMap:
      name: nginx-config
```

**Deploy and test:**

```bash
kubectl apply -f nginx-config.yaml
kubectl apply -f configmap-volume-pod.yaml

# Wait for pod
kubectl wait --for=condition=Ready pod/configmap-volume-pod --timeout=60s

# Test configuration
kubectl exec configmap-volume-pod -- curl localhost:8080
kubectl exec configmap-volume-pod -- cat /etc/nginx/nginx.conf
```

### Exercise 2.2: Secret as Volume

**Create Secret:**

```bash
# Create TLS secret
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=example.com/O=example"

kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key
```

**Use Secret in Pod:**

```yaml
# secret-volume-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
spec:
  containers:
  - name: app
    image: nginx:1.25
    volumeMounts:
    - name: tls-volume
      mountPath: /etc/tls
      readOnly: true
    command: ["sh", "-c"]
    args:
    - |
      echo "TLS Certificate:"
      cat /etc/tls/tls.crt
      echo "---"
      echo "Files in /etc/tls:"
      ls -la /etc/tls/
      sleep 3600

  volumes:
  - name: tls-volume
    secret:
      secretName: tls-secret
      defaultMode: 0400  # Read-only for owner
```

**Deploy and test:**

```bash
kubectl apply -f secret-volume-pod.yaml

# Check mounted secrets
kubectl exec secret-volume-pod -- ls -la /etc/tls/
kubectl exec secret-volume-pod -- cat /etc/tls/tls.crt
```

**Questions:**

1. What happens when you update a ConfigMap mounted as a volume?
2. How long does it take for ConfigMap changes to propagate to pods?
3. What's the difference between subPath and mounting the entire volume?

---

## Part 3: PersistentVolumes and PersistentVolumeClaims

### Exercise 3.1: Create PersistentVolume (Manual Provisioning)

**Create PersistentVolume:**

```yaml
# persistent-volume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: manual-pv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data
    type: DirectoryOrCreate
```

**Create PersistentVolumeClaim:**

```yaml
# persistent-volume-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: manual-pvc
spec:
  storageClassName: manual
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

**Deploy and verify:**

```bash
kubectl apply -f persistent-volume.yaml
kubectl apply -f persistent-volume-claim.yaml

# Check PV status
kubectl get pv

# Check PVC status (should be Bound)
kubectl get pvc

# Describe to see binding
kubectl describe pv manual-pv
kubectl describe pvc manual-pvc
```

### Exercise 3.2: Use PVC in Pod

**Create pod using PVC:**

```yaml
# pvc-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
  - name: app
    image: nginx:1.25
    ports:
    - containerPort: 80
    volumeMounts:
    - name: persistent-storage
      mountPath: /usr/share/nginx/html

  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: manual-pvc
```

**Deploy and test:**

```bash
kubectl apply -f pvc-pod.yaml

# Wait for pod
kubectl wait --for=condition=Ready pod/pvc-pod --timeout=60s

# Write data to persistent volume
kubectl exec pvc-pod -- sh -c 'echo "Hello from PVC!" > /usr/share/nginx/html/index.html'

# Test
kubectl exec pvc-pod -- curl localhost

# Delete and recreate pod to verify persistence
kubectl delete pod pvc-pod
kubectl apply -f pvc-pod.yaml
kubectl wait --for=condition=Ready pod/pvc-pod --timeout=60s

# Data should persist
kubectl exec pvc-pod -- curl localhost
```

### Exercise 3.3: Access Modes

Kubernetes supports three access modes:

- **ReadWriteOnce (RWO)**: Volume can be mounted as read-write by a single node
- **ReadOnlyMany (ROX)**: Volume can be mounted as read-only by many nodes
- **ReadWriteMany (RWX)**: Volume can be mounted as read-write by many nodes

**Create ReadWriteMany PV (requires NFS or similar):**

```yaml
# rwx-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: shared-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: shared
  hostPath:  # For demo only; use NFS in production
    path: /mnt/shared
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-pvc
spec:
  accessModes:
  - ReadWriteMany
  storageClassName: shared
  resources:
    requests:
      storage: 1Gi
```

**Use in multiple pods:**

```yaml
# shared-pods.yaml
apiVersion: v1
kind: Pod
metadata:
  name: writer-pod
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c"]
    args:
    - |
      while true; do
        echo "$(date): Message from writer-pod" >> /data/shared.log
        sleep 5
      done
    volumeMounts:
    - name: shared-storage
      mountPath: /data
  volumes:
  - name: shared-storage
    persistentVolumeClaim:
      claimName: shared-pvc
---
apiVersion: v1
kind: Pod
metadata:
  name: reader-pod
spec:
  containers:
  - name: reader
    image: busybox:1.36
    command: ["sh", "-c"]
    args:
    - |
      while true; do
        if [ -f /data/shared.log ]; then
          tail -5 /data/shared.log
        fi
        sleep 10
      done
    volumeMounts:
    - name: shared-storage
      mountPath: /data
  volumes:
  - name: shared-storage
    persistentVolumeClaim:
      claimName: shared-pvc
```

**Questions:**

1. What happens to a PV when its PVC is deleted with Retain policy?
2. Can you bind a PVC requesting ReadWriteMany to a PV with ReadWriteOnce?
3. What's the difference between Delete and Retain reclaim policies?

---

## Part 4: StorageClasses and Dynamic Provisioning

### Exercise 4.1: Create StorageClass

**Create StorageClass:**

```yaml
# storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner  # Use appropriate provisioner
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
```

**For cloud providers, example with AWS EBS:**

```yaml
# aws-storageclass.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: aws-ebs-fast
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
```

**Check available StorageClasses:**

```bash
kubectl get storageclass

# Get default StorageClass
kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'
```

### Exercise 4.2: Dynamic Provisioning with PVC

**Create PVC with StorageClass:**

```yaml
# dynamic-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: standard  # Use your cluster's default or specific class
  resources:
    requests:
      storage: 1Gi
```

**Deploy and verify:**

```bash
kubectl apply -f dynamic-pvc.yaml

# Watch PVC become Bound (PV created automatically)
kubectl get pvc dynamic-pvc -w

# Check auto-created PV
kubectl get pv

# Describe to see provisioning details
kubectl describe pvc dynamic-pvc
```

**Use in deployment:**

```yaml
# dynamic-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 1
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
        volumeMounts:
        - name: web-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: web-storage
        persistentVolumeClaim:
          claimName: dynamic-pvc
```

### Exercise 4.3: Volume Expansion

**Enable volume expansion (if supported):**

```bash
# Check if StorageClass allows expansion
kubectl get storageclass standard -o jsonpath='{.allowVolumeExpansion}'
```

**Expand PVC:**

```bash
# Edit PVC to increase size
kubectl patch pvc dynamic-pvc -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'

# Watch for resize
kubectl get pvc dynamic-pvc -w

# Verify new size
kubectl describe pvc dynamic-pvc
```

**Questions:**

1. What does WaitForFirstConsumer do in volumeBindingMode?
2. Can all volume types be expanded?
3. What happens to data during volume expansion?

---

## Part 5: StatefulSets with Storage

### Exercise 5.1: Create StatefulSet with VolumeClaimTemplates

**Create headless service:**

```yaml
# statefulset-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
spec:
  clusterIP: None
  selector:
    app: nginx-stateful
  ports:
  - port: 80
    name: web
```

**Create StatefulSet:**

```yaml
# statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: nginx-headless
  replicas: 3
  selector:
    matchLabels:
      app: nginx-stateful
  template:
    metadata:
      labels:
        app: nginx-stateful
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
        command: ["sh", "-c"]
        args:
        - |
          echo "Hello from $(hostname)" > /usr/share/nginx/html/index.html
          nginx -g 'daemon off;'

  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 1Gi
```

**Deploy and test:**

```bash
kubectl apply -f statefulset-service.yaml
kubectl apply -f statefulset.yaml

# Watch pods come up in order
kubectl get pods -l app=nginx-stateful -w

# Check PVCs created automatically
kubectl get pvc

# Test stable network identity
kubectl run curl-test --image=curlimages/curl:8.5.0 -i --rm --restart=Never -- \
  curl web-0.nginx-headless

# Write unique data to each pod
for i in 0 1 2; do
  kubectl exec web-$i -- sh -c "echo 'Pod web-$i data' > /usr/share/nginx/html/data.txt"
done

# Read data
for i in 0 1 2; do
  echo "=== web-$i ==="
  kubectl exec web-$i -- cat /usr/share/nginx/html/data.txt
done

# Delete a pod and verify data persists
kubectl delete pod web-1
kubectl wait --for=condition=Ready pod/web-1 --timeout=60s
kubectl exec web-1 -- cat /usr/share/nginx/html/data.txt
```

### Exercise 5.2: Scale StatefulSet

**Scale up:**

```bash
kubectl scale statefulset web --replicas=5

# Watch new pods and PVCs created
kubectl get pods -l app=nginx-stateful -w
kubectl get pvc
```

**Scale down:**

```bash
kubectl scale statefulset web --replicas=2

# Pods deleted in reverse order
kubectl get pods -l app=nginx-stateful -w

# Note: PVCs are NOT deleted automatically
kubectl get pvc
```

**Questions:**

1. How does StatefulSet differ from Deployment in terms of storage?
2. What happens to PVCs when you scale down a StatefulSet?
3. Why does StatefulSet need a headless service?

---

## Part 6: Storage Best Practices

### Exercise 6.1: Resource Limits and Quotas

**Create ResourceQuota for storage:**

```yaml
# storage-quota.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: storage-limited
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: storage-quota
  namespace: storage-limited
spec:
  hard:
    requests.storage: 10Gi
    persistentvolumeclaims: "5"
```

**Test quota:**

```bash
kubectl apply -f storage-quota.yaml

# Try to create PVC exceeding quota
kubectl create -n storage-limited -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: large-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 15Gi
EOF
# Should be rejected
```

### Exercise 6.2: Volume Snapshots (if supported)

**Create VolumeSnapshot:**

```yaml
# volume-snapshot.yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: pvc-snapshot
spec:
  volumeSnapshotClassName: csi-snapclass
  source:
    persistentVolumeClaimName: dynamic-pvc
```

**Restore from snapshot:**

```yaml
# restore-from-snapshot.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: standard
  dataSource:
    name: pvc-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
  resources:
    requests:
      storage: 1Gi
```

### Exercise 6.3: Volume Security

**Secure volume with fsGroup:**

```yaml
# secure-volume-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-volume-pod
spec:
  securityContext:
    fsGroup: 2000
    runAsUser: 1000
    runAsGroup: 3000

  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "ls -la /data && sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true

  volumes:
  - name: data
    emptyDir: {}
```

**Deploy and verify:**

```bash
kubectl apply -f secure-volume-pod.yaml

# Check ownership
kubectl exec secure-volume-pod -- ls -la /data
# Should show group ownership as 2000 (fsGroup)
```

---

## Verification Questions

1. **Volume Types:**
   - When should you use emptyDir vs PVC?
   - What are the risks of using hostPath?
   - How is data lifecycle different between volume types?

2. **PV and PVC:**
   - What's the relationship between PV and PVC?
   - How does binding work between PV and PVC?
   - What are reclaim policies and when to use each?

3. **StorageClasses:**
   - What does a StorageClass provisioner do?
   - How does dynamic provisioning work?
   - What is volumeBindingMode?

4. **StatefulSets:**
   - Why do StatefulSets need volumeClaimTemplates?
   - What happens to PVCs when StatefulSet is deleted?
   - How is pod identity maintained across restarts?

5. **Best Practices:**
   - Should you use ReadWriteMany by default?
   - How do you backup PVCs?
   - What security considerations apply to volumes?

---

## Cleanup

```bash
# Delete pods
kubectl delete pod emptydir-pod emptydir-advanced hostpath-pod configmap-volume-pod secret-volume-pod pvc-pod writer-pod reader-pod secure-volume-pod

# Delete StatefulSet
kubectl delete statefulset web
kubectl delete svc nginx-headless

# Delete PVCs (careful - deletes data!)
kubectl delete pvc manual-pvc shared-pvc dynamic-pvc
kubectl delete pvc -l app=nginx-stateful

# Delete PVs
kubectl delete pv manual-pv shared-pv

# Delete StorageClass
kubectl delete storageclass fast-storage

# Delete ConfigMaps and Secrets
kubectl delete configmap nginx-config
kubectl delete secret tls-secret
rm -f tls.key tls.crt

# Delete namespace
kubectl delete namespace storage-limited

# Delete deployment
kubectl delete deployment web-app
```

---

## Challenge Exercise

Create a complete stateful application with:

1. **PostgreSQL StatefulSet:**
   - 3 replicas with persistent storage
   - Each replica has its own PVC (1Gi)
   - Proper init containers for setup
   - Headless service for stable network identity

2. **Storage requirements:**
   - Use StorageClass with dynamic provisioning
   - Enable volume expansion
   - Implement backup strategy using snapshots
   - Set appropriate reclaim policy

3. **Configuration:**
   - Database credentials in Secret
   - Configuration in ConfigMap
   - Both mounted as volumes

4. **Security:**
   - Run as non-root user
   - Use fsGroup for proper permissions
   - Read-only root filesystem where possible

5. **Testing:**
   - Write data to database
   - Delete a pod and verify data persists
   - Scale up/down and verify stability
   - Test backup and restore

**Deliverables:**

- All YAML manifests
- Backup/restore procedures
- Test scripts
- Documentation of storage architecture
- Performance considerations

---

## Additional Resources

- [Kubernetes Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)

---

## Key Takeaways

- EmptyDir is temporary and deleted when pod is removed
- PVs and PVCs decouple storage from pod lifecycle
- StorageClasses enable dynamic provisioning
- StatefulSets provide stable storage per pod
- Access modes determine how volumes can be shared
- ConfigMaps and Secrets can be mounted as volumes
- Always consider data persistence and backup strategies
- Security contexts affect volume permissions
