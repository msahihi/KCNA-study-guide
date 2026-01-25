# KCNA Mock Exam - Set 2

**Total Questions**: 60
**Time Limit**: 90 minutes
**Passing Score**: 75% (45 correct answers)

## Exam Domain Distribution

Questions are distributed according to official KCNA exam weights:

- **Kubernetes Fundamentals (44%)**: Questions 1-27
- **Container Orchestration (28%)**: Questions 28-44
- **Cloud Native Application Delivery (16%)**: Questions 45-53
- **Cloud Native Architecture (12%)**: Questions 54-60

---

## Section 1: Kubernetes Fundamentals (Questions 1-27)

### Question 1

What is the primary difference between `kubectl cordon` and `kubectl taint`?

A. Cordon is for permanent node removal; taint is temporary  
B. Cordon marks node unschedulable; taint provides granular control with tolerations  
C. Cordon evicts pods; taint prevents scheduling  
D. They are identical in functionality  

**Answer: B**

<details>
<summary>Explanation</summary>

Key differences:

- **kubectl cordon**: Simple, marks node unschedulable, no additional configuration needed
- **kubectl taint**: More flexible, requires pod tolerations, allows dedicated nodes for specific workloads

</details>

### Question 2

Which kubectl command would you use to create a pod imperatively?

A. `kubectl apply -f pod.yaml`  
B. `kubectl create pod mypod --image=nginx`  
C. `kubectl run mypod --image=nginx`  
D. `kubectl generate pod mypod --image=nginx`  

**Answer: C**

<details>
<summary>Explanation</summary>

`kubectl run` is the imperative command to create pods. `kubectl apply -f` is declarative (uses YAML file). `kubectl create pod` is not a valid command format.

</details>

### Question 3

What is the purpose of a readiness probe?

A. To restart unhealthy containers  
B. To determine when a container is ready to accept traffic  
C. To check if a container needs more resources  
D. To monitor container logs  

**Answer: B**

<details>
<summary>Explanation</summary>

Readiness probes tell Kubernetes when a container is ready to serve requests. Failed readiness probes remove the pod from service endpoints but don't restart the container. Liveness probes restart containers.

</details>

### Question 4

Which Kubernetes object automatically manages the lifecycle of pods in a deployment?

A. Service  
B. ReplicaSet  
C. ConfigMap  
D. Namespace  

**Answer: B**

<details>
<summary>Explanation</summary>

Deployments create and manage ReplicaSets, which in turn manage pods. The ReplicaSet ensures the desired number of pod replicas are running. Deployments handle rolling updates by creating new ReplicaSets.

</details>

### Question 5

What is the default namespace in Kubernetes?

A. kube-system  
B. kube-public  
C. default  
D. production  

**Answer: C**

<details>
<summary>Explanation</summary>

The default namespace is where resources are created if no namespace is specified. Other system namespaces: kube-system (system components), kube-public (publicly readable), kube-node-lease (node heartbeats).

</details>

### Question 6

You want to deploy a stateless web application that can be easily scaled. Which workload type should you use?

A. StatefulSet  
B. DaemonSet  
C. Deployment  
D. Job  

**Answer: C**

<details>
<summary>Explanation</summary>

Stateless web applications are perfect for Deployments:

- No persistent data requirements
- Pods are interchangeable
- Easy horizontal scaling
- Rolling updates

</details>

### Question 7

Which command shows the current context of your kubectl configuration?

A. `kubectl config view`  
B. `kubectl config current-context`  
C. `kubectl context`  
D. `kubectl get context`  

**Answer: B**

<details>
<summary>Explanation</summary>

`kubectl config current-context` shows the active context. `kubectl config view` shows the entire config file. Contexts define cluster, user, and namespace combinations.

</details>

### Question 8

What happens when you delete a pod that is managed by a deployment?

A. The pod is permanently removed  
B. The ReplicaSet creates a new pod to maintain the desired count  
C. The deployment is automatically deleted  
D. All containers in the pod are archived  

**Answer: B**

<details>
<summary>Explanation</summary>

When a pod managed by a Deployment is deleted, the ReplicaSet controller immediately creates a replacement pod to maintain the desired replica count. This ensures high availability.

</details>

### Question 9

Which kubectl command can you use to label a pod?

A. `kubectl label pod <name> key=value`  
B. `kubectl tag pod <name> key=value`  
C. `kubectl annotate pod <name> key=value`  
D. `kubectl set label pod <name> key=value`  

**Answer: A**

<details>
<summary>Explanation</summary>

`kubectl label` adds or modifies labels. Add `--overwrite` to change existing labels. Remove labels with `key-` (minus sign). Annotations use `kubectl annotate` and are for non-identifying metadata.

</details>

### Question 10

What is the purpose of an annotation in Kubernetes?

A. To select groups of objects  
B. To attach non-identifying metadata to objects  
C. To enforce security policies  
D. To define resource requests  

**Answer: B**

<details>
<summary>Explanation</summary>

Annotations store arbitrary metadata that doesn't identify objects (unlike labels). Common uses:

- Build information
- Tool configuration
- Contact information

Annotations can't be used in selectors.

</details>

### Question 11

Which component stores the cluster state in Kubernetes?

A. API Server  
B. etcd  
C. Controller Manager  
D. kubelet  

**Answer: B**

<details>
<summary>Explanation</summary>

etcd is a distributed key-value store that holds the entire cluster state. The API server reads from and writes to etcd. All Kubernetes data is stored in etcd (pods, services, secrets, etc.).

</details>

### Question 12

What kubectl command scales a deployment to 5 replicas?

A. `kubectl scale deployment myapp --replicas=5`  
B. `kubectl set replicas deployment myapp 5`  
C. `kubectl update deployment myapp --replicas=5`  
D. `kubectl modify deployment myapp replicas=5`  

**Answer: A**

<details>
<summary>Explanation</summary>

`kubectl scale` is the imperative command for scaling. It updates the replica count in the deployment spec. You can also edit the deployment YAML directly.

</details>

### Question 13

Which kubectl command can display resource usage (CPU/memory) for pods?

A. `kubectl top pods`  
B. `kubectl stats pods`  
C. `kubectl usage pods`  
D. `kubectl resources pods`  

**Answer: A**

<details>
<summary>Explanation</summary>

`kubectl top` shows current resource usage (requires metrics-server). `kubectl top pods` shows CPU/memory per pod. `kubectl top nodes` shows node-level usage.

</details>

### Question 14

What is the purpose of a toleration in Kubernetes?

A. To prevent pods from being scheduled  
B. To allow pods to be scheduled on nodes with matching taints  
C. To increase pod priority  
D. To define resource limits  

**Answer: B**

<details>
<summary>Explanation</summary>

Tolerations allow pods to be scheduled on tainted nodes. A pod must have a toleration matching a node's taint to be scheduled there. Example:

```yaml

tolerations:

- key: "gpu"

  operator: "Equal"
  value: "true"
  effect: "NoSchedule"

```

</details>

### Question 15

Which file is kubectl configuration typically stored in?

A. `~/.kube/config`  
B. `/etc/kubernetes/config`  
C. `~/kubectl.conf`  
D. `/var/lib/kubelet/config`  

**Answer: A**

<details>
<summary>Explanation</summary>

The default kubectl config file is `~/.kube/config`. It contains contexts, clusters, and user credentials. You can specify different config files with `--kubeconfig` or `KUBECONFIG` environment variable.

</details>

### Question 16

What happens when a startup probe fails?

A. The container is marked unhealthy but continues running  
B. The container is killed and restarted according to restart policy  
C. The pod is deleted immediately  
D. Nothing, it's just logged  

**Answer: B**

<details>
<summary>Explanation</summary>

Startup probes protect slow-starting containers. If startup probe fails after all retries, the container is killed and restarted. Liveness and readiness probes are disabled until startup succeeds.

</details>

### Question 17

Which kubectl command displays events for the cluster?

A. `kubectl get events`  
B. `kubectl logs events`  
C. `kubectl describe events`  
D. `kubectl show events`  

**Answer: A**

<details>
<summary>Explanation</summary>

`kubectl get events` lists cluster events. Add `--watch` to stream events. Events show pod scheduling, image pulls, errors, and warnings. Events are namespace-scoped.

</details>

### Question 18

What is the purpose of a PersistentVolumeClaim (PVC)?

A. To create a new storage volume on a node  
B. To request storage resources from a PersistentVolume  
C. To delete unused volumes  
D. To configure network storage  

**Answer: B**

<details>
<summary>Explanation</summary>

PersistentVolumeClaims (PVCs) request storage. Workflow:

1. Admin creates PersistentVolume (PV)
2. User creates PVC requesting size and access mode
3. Kubernetes binds PVC to suitable PV
4. Pod references PVC

</details>

### Question 19

Which kubectl command can create resources from a YAML file?

A. `kubectl create -f file.yaml`  
B. `kubectl apply -f file.yaml`  
C. Both A and B  
D. `kubectl generate -f file.yaml`  

**Answer: C**

<details>
<summary>Explanation</summary>

Both commands work:

- `kubectl create -f`: Creates resources, fails if they exist
- `kubectl apply -f`: Creates or updates resources declaratively (recommended for GitOps)

</details>

### Question 20

What is the primary function of kube-proxy?

A. To schedule pods  
B. To manage network rules for pod communication  
C. To store cluster configuration  
D. To run containers  

**Answer: B**

<details>
<summary>Explanation</summary>

kube-proxy runs on each node and manages network rules (iptables/IPVS). It enables:

- Service IP to pod IP mapping
- Load balancing across pods
- ClusterIP implementation

</details>

### Question 21

Which Pod Security Standard allows unrestricted access and privileges?

A. Baseline  
B. Restricted  
C. Privileged  
D. Permissive  

**Answer: C**

<details>
<summary>Explanation</summary>

The Privileged Pod Security Standard is unrestricted, allowing:

- Running as root
- All capabilities
- Host access

Only use for trusted system workloads.

</details>

### Question 22

What command would you use to drain a node for maintenance, ignoring DaemonSet pods?

A. `kubectl drain <node> --force`  
B. `kubectl drain <node> --ignore-daemonsets`  
C. `kubectl evict <node> --all`  
D. `kubectl cordon <node> --evict`  

**Answer: B**

<details>
<summary>Explanation</summary>

`kubectl drain` evicts pods and cordons the node. `--ignore-daemonsets` is required because DaemonSet pods can't be drained (they run on every node). Use `--force` for pods not managed by controllers.

</details>

### Question 23

Which resource type ensures that a job runs to completion?

A. Deployment  
B. ReplicaSet  
C. Job  
D. CronJob  

**Answer: C**

<details>
<summary>Explanation</summary>

Jobs create pods that run to completion. They ensure tasks finish successfully:

- Batch processing
- Data processing
- Backups

Jobs track successful completions and retry failures.

</details>

### Question 24

What is the difference between a Job and a CronJob?

A. Jobs run continuously; CronJobs run once  
B. Jobs run once; CronJobs run on a schedule  
C. Jobs are for batch processing; CronJobs are for web services  
D. There is no difference  

**Answer: B**

<details>
<summary>Explanation</summary>

- **Job**: Runs once, ensures completion
- **CronJob**: Creates Jobs on a schedule (cron format)

CronJobs are for recurring tasks like backups, reports, cleanup.

</details>

### Question 25

Which kubectl command exports a resource definition in YAML format?

A. `kubectl get <resource> <name> -o yaml`  
B. `kubectl export <resource> <name> --format=yaml`  
C. `kubectl describe <resource> <name> --yaml`  
D. `kubectl show <resource> <name> -o yaml`  

**Answer: A**

<details>
<summary>Explanation</summary>

`-o yaml` outputs in YAML format. Other formats: `-o json`, `-o wide`, `-o name`. Useful for backing up resources or creating templates.

</details>

### Question 26

What is the purpose of a service selector?

A. To choose which namespace a service operates in  
B. To identify which pods the service routes traffic to  
C. To select which nodes can run the service  
D. To configure service type  

**Answer: B**

<details>
<summary>Explanation</summary>

Services use selectors to identify target pods. Example:

```yaml

selector:
  app: web
  tier: frontend

```

Service routes traffic to pods with matching labels.

</details>

### Question 27

Which controller ensures that the desired number of nodes are running in the cluster?

A. ReplicaSet  
B. Deployment  
C. Node Controller  
D. Scheduler  

**Answer: C**

<details>
<summary>Explanation</summary>

The Node Controller is part of the controller-manager. It:

- Monitors node health
- Manages node lifecycle
- Evicts pods from unhealthy nodes
- Updates node status

</details>

---

## Section 2: Container Orchestration (Questions 28-44)

### Question 28

When should you use a StatefulSet instead of a Deployment?

A. When you need more replicas  
B. When you need stable network identifiers and persistent storage  
C. When you want faster deployments  
D. When you don't need rolling updates  

**Answer: B**

<details>
<summary>Explanation</summary>

Use StatefulSet when applications require:

- Stable, unique network identities (pod-0, pod-1, etc.)
- Persistent storage per pod
- Ordered deployment and scaling
- Ordered updates and deletions

Examples: databases, message queues, clustered applications.

</details>

### Question 29

What is the correct order of pod termination in a StatefulSet with 3 replicas (pod-0, pod-1, pod-2)?

A. pod-0, pod-1, pod-2  
B. pod-2, pod-1, pod-0  
C. Random order  
D. All terminate simultaneously  

**Answer: B**

<details>
<summary>Explanation</summary>

StatefulSets terminate pods in reverse order of their ordinals:

- Creation: pod-0 → pod-1 → pod-2
- Deletion: pod-2 → pod-1 → pod-0

This ensures ordered shutdown for stateful applications.

</details>

### Question 30

Which volume type persists data beyond the pod's lifecycle?

A. emptyDir  
B. PersistentVolume  
C. configMap  
D. secret  

**Answer: B**

<details>
<summary>Explanation</summary>

PersistentVolumes provide durable storage that persists beyond pod lifecycle. emptyDir is deleted when the pod is removed. PVs enable:

- Data persistence across pod restarts
- Data migration when pods move nodes
- Independent storage lifecycle

</details>

### Question 31

What is a sidecar container pattern used for?

A. Replacing the main container  
B. Enhancing the main container with additional functionality (logging, monitoring, etc.)  
C. Scheduling the main container  
D. Storing backup data  

**Answer: B**

<details>
<summary>Explanation</summary>

Sidecar pattern uses:

- Log aggregators (collecting logs to central system)
- Service mesh proxies (Envoy, Linkerd)
- Configuration reloaders
- Monitoring agents

Sidecars run alongside and enhance the main container.

</details>

### Question 32

Which network policy direction controls traffic leaving pods?

A. Ingress  
B. Egress  
C. Outbound  
D. External  

**Answer: B**

<details>
<summary>Explanation</summary>

Network Policy directions:

- **Ingress**: Controls incoming traffic TO pods
- **Egress**: Controls outgoing traffic FROM pods

Example: Restrict database pods to only accept traffic from app pods (ingress), and only connect to specific external APIs (egress).

</details>

### Question 33

What is the purpose of a hostPath volume?

A. To mount a file or directory from the host node into a pod  
B. To create network storage  
C. To share data between pods  
D. To store secrets  

**Answer: A**

<details>
<summary>Explanation</summary>

hostPath volumes mount a file or directory from the node's filesystem. Use cases:

- Access node-level data
- Run privileged containers
- Testing

⚠️ Security risk: Pods can access host filesystem. Avoid in multi-tenant clusters.

</details>

### Question 34

Which container runtime is NOT CRI-compliant?

A. containerd  
B. CRI-O  
C. rkt (unmaintained)  
D. Docker Engine (without dockershim)  

**Answer: D**

<details>
<summary>Explanation</summary>

CRI-compliant runtimes:

- ✅ containerd (most common)
- ✅ CRI-O
- ❌ Docker Engine requires dockershim (deprecated in K8s 1.20, removed in 1.24)

containerd is now the standard runtime.

</details>

### Question 35

What metrics can HPA use for autoscaling?

A. CPU and memory only  
B. CPU, memory, and custom metrics  
C. Network traffic only  
D. Disk I/O only  

**Answer: B**

<details>
<summary>Explanation</summary>

HPA supports multiple metric sources:

- Resource metrics: CPU, memory (from metrics-server)
- Custom metrics: Application-specific (via custom metrics API)
- External metrics: Cloud provider metrics

Can combine multiple metrics with different target values.

</details>

### Question 36

Which resource type is best for running a monitoring agent on every node?

A. Deployment  
B. StatefulSet  
C. DaemonSet  
D. ReplicaSet  

**Answer: C**

<details>
<summary>Explanation</summary>

DaemonSets run one pod per node, perfect for:

- Node monitoring agents (Prometheus Node Exporter)
- Log collectors (Fluentd, Filebeat)
- Storage daemons (Ceph, Gluster)
- Network plugins (Calico, Weave)

</details>

### Question 37

What is the primary task of the Kubernetes scheduler?

A. To monitor pod health  
B. To assign pods to nodes based on resource requirements and constraints  
C. To manage container lifecycle  
D. To handle network routing  

**Answer: B**

<details>
<summary>Explanation</summary>

Scheduler responsibilities:

- Filter nodes that meet pod requirements
- Score nodes based on optimization rules
- Select best node for the pod
- Consider: resources, taints/tolerations, affinity, topology

Does NOT monitor health—that's kubelet's job.

</details>

### Question 38

How should you encrypt Secrets at rest in Kubernetes?

A. Secrets are automatically encrypted  
B. Enable encryption in the API server configuration  
C. Use base64 encoding  
D. Store them in ConfigMaps instead  

**Answer: B**

<details>
<summary>Explanation</summary>

Secrets are base64 encoded by default (NOT encrypted). To encrypt:

1. Create encryption configuration
2. Configure API server with `--encryption-provider-config`
3. Restart API server
4. Encrypt existing secrets with `kubectl get secrets --all-namespaces -o json | kubectl replace -f -`

</details>

### Question 39

What is the default encoding method for Kubernetes Secrets?

A. AES-256 encryption  
B. Base64 encoding (not encrypted)  
C. SHA-256 hashing  
D. Plain text  

**Answer: B**

<details>
<summary>Explanation</summary>

Important distinction:

- **Encoding (base64)**: Transforms data, easily reversible, NOT security
- **Encryption**: Uses keys, secure, hard to reverse

Default Secrets are only base64 encoded. Anyone with etcd access can decode them.

</details>

### Question 40

Which taint effect will evict existing pods and prevent new ones from being scheduled?

A. NoSchedule  
B. PreferNoSchedule  
C. NoExecute  
D. EvictAll  

**Answer: C**

<details>
<summary>Explanation</summary>

Taint effects:

- **NoSchedule**: Prevents new pods, existing pods stay
- **PreferNoSchedule**: Soft preference to avoid node
- **NoExecute**: Evicts existing pods without tolerations AND prevents new pods

NoExecute is the strongest effect.

</details>

### Question 41

You want to dedicate a node to GPU workloads. What should you do?

A. Use a DaemonSet  
B. Apply a taint to the node and add tolerations to GPU pods  
C. Use a StatefulSet  
D. Label the pods only  

**Answer: B**

<details>
<summary>Explanation</summary>

Dedicated node pattern:

```bash

# Taint node
kubectl taint nodes gpu-node gpu=true:NoSchedule

# GPU pods need toleration
tolerations:

- key: "gpu"

  operator: "Equal"
  value: "true"
  effect: "NoSchedule"

```

Also add nodeSelector for additional targeting.

</details>

### Question 42

What happens if a pod doesn't have a toleration for a node's taint?

A. The pod runs anyway  
B. The pod is scheduled but runs slowly  
C. The pod cannot be scheduled on that node  
D. The taint is removed  

**Answer: C**

<details>
<summary>Explanation</summary>

Taints repel pods. Without matching tolerations, the scheduler skips tainted nodes. This is how you dedicate nodes to specific workloads or prevent certain pods from running.

</details>

### Question 43

Which workload type maintains the order of pod creation and deletion?

A. Deployment  
B. StatefulSet  
C. DaemonSet  
D. ReplicaSet  

**Answer: B**

<details>
<summary>Explanation</summary>

StatefulSets guarantee ordering:

- **Creation**: Sequential (pod-0 first, then pod-1, etc.)
- **Deletion**: Reverse sequential (pod-N first, down to pod-0)
- **Updates**: Ordered rolling updates

Deployments create/delete pods in any order.

</details>

### Question 44

What is the difference between ConfigMap and Secret?

A. ConfigMap is for non-sensitive data; Secret is for sensitive data  
B. ConfigMap is encrypted; Secret is not  
C. They are identical  
D. ConfigMap is only for environment variables  

**Answer: A**

<details>
<summary>Explanation</summary>

- **ConfigMap**: Configuration, environment variables, config files
- **Secret**: Passwords, tokens, SSH keys, TLS certificates

Both can be consumed as:

- Environment variables
- Command-line arguments
- Files in volumes

</details>

---

## Section 3: Cloud Native Application Delivery (Questions 45-53)

### Question 45

When would you choose ArgoCD over Helm?

A. For simple one-time deployments  
B. For GitOps-based continuous delivery across multiple clusters  
C. For building container images  
D. For monitoring applications  

**Answer: B**

<details>
<summary>Explanation</summary>

Choose ArgoCD when you need:

- GitOps workflow (Git as source of truth)
- Multi-cluster deployment
- Automatic synchronization
- Drift detection and auto-healing
- Declarative setup

Choose Helm for package management and templating.

</details>

### Question 46

What is the main purpose of Helm?

A. To monitor Kubernetes clusters  
B. To package and manage Kubernetes applications  
C. To build container images  
D. To manage network policies  

**Answer: B**

<details>
<summary>Explanation</summary>

Helm is a package manager that:

- Packages apps as charts
- Manages dependencies
- Supports versioning and rollback
- Provides templating for customization
- Enables sharing via repositories

</details>

### Question 47

What is stored in a Helm values file?

A. Container images  
B. Configuration parameters that can be customized  
C. Network policies  
D. User authentication tokens  

**Answer: B**

<details>
<summary>Explanation</summary>

values.YAML contains:

- Default configuration values
- Parameters that can be overridden during installation
- Environment-specific settings

Install with custom values: `helm install myapp mychart -f custom-values.YAML`

</details>

### Question 48

What deployment strategy gradually shifts traffic from old to new versions?

A. Blue-green deployment  
B. Canary deployment  
C. Rolling update  
D. Recreate  

**Answer: B**

<details>
<summary>Explanation</summary>

Deployment strategies:

- **Rolling update**: Gradual replacement (default)
- **Blue-green**: Complete switch between environments
- **Canary**: Gradual traffic shift (e.g., 10% → 50% → 100%)
- **Recreate**: Delete all, then create new

Canary reduces risk by exposing changes to small percentage first.

</details>

### Question 49

What is the primary benefit of using GitOps?

A. Faster container startup  
B. Declarative, version-controlled infrastructure and automatic synchronization  
C. Lower costs  
D. Simpler networking  

**Answer: B**

<details>
<summary>Explanation</summary>

GitOps benefits:

- Git as single source of truth
- Version control for infrastructure
- Audit trail (who changed what, when)
- Easy rollback (git revert)
- Automated deployments
- Drift detection

</details>

### Question 50

Which Gateway API resource defines the actual gateway that handles traffic?

A. GatewayClass  
B. Gateway  
C. HTTPRoute  
D. Service  

**Answer: B**

<details>
<summary>Explanation</summary>

Gateway API resources:

- **GatewayClass**: Defines class of gateways (like IngressClass)
- **Gateway**: Actual gateway instance that listens for traffic
- **HTTPRoute/TCPRoute**: Routing rules

Gateway is the infrastructure, Routes are the traffic rules.

</details>

### Question 51

What is an advantage of Gateway API over Ingress?

A. It only works with HTTP  
B. It supports multiple protocols (HTTP, TCP, UDP, gRPC) and has role-oriented design  
C. It requires less configuration  
D. It uses less memory  

**Answer: B**

<details>
<summary>Explanation</summary>

Gateway API advantages:

- Multi-protocol: Not just HTTP/HTTPS
- Role-oriented: Infrastructure vs. application teams
- Expressive: Built-in advanced features
- Portable: Less vendor lock-in
- Extensible: Standardized extension mechanism

</details>

### Question 52

What is the role of an Ingress controller?

A. To schedule pods  
B. To implement the rules defined in Ingress resources  
C. To manage secrets  
D. To monitor applications  

**Answer: B**

<details>
<summary>Explanation</summary>

Ingress controllers:

- Watch for Ingress resources
- Configure underlying load balancer (nginx, HAProxy, Traefik)
- Handle HTTP/HTTPS routing
- Manage TLS termination

Popular controllers: nginx, Traefik, HAProxy, Istio.

</details>

### Question 53

Which practice is central to GitOps?

A. Manual deployments  
B. Git repository as the source of truth for desired state  
C. Direct kubectl commands  
D. Binary configuration files  

**Answer: B**

<details>
<summary>Explanation</summary>

GitOps core practices:

- Infrastructure/applications described declaratively in Git
- Automated agents sync Git state to clusters
- No manual kubectl commands
- Changes via pull requests
- Continuous reconciliation

</details>

---

## Section 4: Cloud Native Architecture (Questions 54-60)

### Question 54

Which tool is used for distributed tracing in cloud-native applications?

A. Prometheus  
B. Jaeger  
C. Fluentd  
D. CoreDNS  

**Answer: B**

<details>
<summary>Explanation</summary>

Distributed tracing tools:

- **Jaeger**: CNCF distributed tracing platform
- **Zipkin**: Twitter's tracing system
- **OpenTelemetry**: Vendor-neutral observability framework

Prometheus is for metrics, not traces.

</details>

### Question 55

What does Prometheus primarily collect?

A. Application logs  
B. Metrics (time-series data)  
C. Distributed traces  
D. Container images  

**Answer: B**

<details>
<summary>Explanation</summary>

Prometheus collects:

- Metrics: Time-series data (counters, gauges, histograms)
- Examples: CPU usage, request rate, error rate, response time

Not for:

- Logs (use Fluentd, Loki)
- Traces (use Jaeger, Zipkin)

</details>

### Question 56

What is a "trace" in distributed tracing?

A. A single log entry  
B. The complete journey of a request through multiple services  
C. A network packet  
D. A container event  

**Answer: B**

<details>
<summary>Explanation</summary>

Tracing terminology:

- **Trace**: End-to-end request flow across all services
- **Span**: Single operation within the trace
- **Tag**: Metadata attached to spans

Example: Web request → API → Database (one trace, three spans).

</details>

### Question 57

Which image pull policy pulls the image only if it doesn't exist locally?

A. Always  
B. Never  
C. IfNotPresent  
D. OnDemand  

**Answer: C**

<details>
<summary>Explanation</summary>

Image pull policies:

- **IfNotPresent**: Pull only if not in local cache (default for tagged images)
- **Always**: Always pull latest (default for :latest tag)
- **Never**: Only use local images

IfNotPresent is most common for specific version tags.

</details>

### Question 58

What is the CNCF's mission?

A. To sell cloud services  
B. To provide a vendor-neutral home for open-source cloud-native projects  
C. To replace Kubernetes  
D. To compete with major cloud providers  

**Answer: B**

<details>
<summary>Explanation</summary>

CNCF mission:

- Host and nurture cloud-native open-source projects
- Vendor-neutral governance
- Foster community and collaboration
- Provide certification programs (KCNA, CKA, etc.)

Part of the Linux Foundation.

</details>

### Question 59

Which cloud-native principle emphasizes designing for failure?

A. Monolithic architecture  
B. Manual intervention  
C. Resilience and fault tolerance  
D. Single point of failure  

**Answer: C**

<details>
<summary>Explanation</summary>

Cloud-native resilience principles:

- Design for failure (expect components to fail)
- Circuit breakers
- Retry and timeout strategies
- Graceful degradation
- Health checks and auto-healing

Avoid single points of failure.

</details>

### Question 60

You need to deploy a message queue (like Kafka) that requires stable network identity for cluster formation. Which workload type should you use?

A. Deployment  
B. DaemonSet  
C. StatefulSet  
D. Job  

**Answer: C**

<details>
<summary>Explanation</summary>

Message queues like Kafka require:

- Stable network identity for cluster formation
- Persistent storage for message retention
- Ordered deployment for proper initialization
- Consistent pod names for addressing

StatefulSet provides all requirements. Kafka brokers need to discover each other reliably.

</details>
