# KCNA Mock Exam - Set 1

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

You need to temporarily prevent new pods from being scheduled on a node for maintenance. Which command should you use?

A. `kubectl taint nodes node1 maintenance=true:NoSchedule`  
B. `kubectl cordon node1`  
C. `kubectl drain node1`  
D. `kubectl delete node node1`  

**Answer: B**

<details>
<summary>Explanation</summary>

`kubectl cordon` marks a node as unschedulable, preventing new pods from being scheduled while existing pods continue running. This is ideal for temporary maintenance. Option A (taint) is more complex and requires pod tolerations. Option C (drain) would evict existing pods. Option D would remove the node entirely.

</details>

### Question 2

What is the primary purpose of an init container in Kubernetes?

A. To run alongside the main container throughout the pod's lifecycle  
B. To perform setup tasks that must complete before the main container starts  
C. To monitor the health of the main container  
D. To handle network traffic for the main container  

**Answer: B**

<details>
<summary>Explanation</summary>

Init containers run to completion before the main application containers start. They're used for setup tasks like waiting for services, populating volumes, or running initialization scripts. They don't run alongside the main container (that's a sidecar).

</details>

### Question 3

Which kubectl command creates a deployment named "web-app" with the nginx image?

A. `kubectl run web-app --image=nginx`  
B. `kubectl create deployment web-app --image=nginx`  
C. `kubectl deploy web-app --image=nginx`  
D. `kubectl apply deployment web-app --image=nginx`  

**Answer: B**

<details>
<summary>Explanation</summary>

`kubectl create deployment` creates a deployment resource. Option A creates a pod, not a deployment. Options C and D use non-existent commands.

</details>

### Question 4

What is the difference between `kubectl create` and `kubectl run`?

A. `kubectl create` creates any resource type; `kubectl run` creates only pods  
B. `kubectl create` is deprecated; `kubectl run` is the new standard  
C. They are identical commands with different syntax  
D. `kubectl create` is for YAML files only; `kubectl run` is for command-line creation  

**Answer: A**

<details>
<summary>Explanation</summary>

`kubectl create` is a general command for creating any Kubernetes resource from specifications. `kubectl run` was historically used for creating deployments but now primarily creates pods. Neither is deprecated.

</details>

### Question 5

Which Pod Security Standard provides the most restrictive security policies?

A. Privileged  
B. Baseline  
C. Restricted  
D. Default  

**Answer: C**

<details>
<summary>Explanation</summary>

The three Pod Security Standards are:

- **Privileged**: Unrestricted (least secure)
- **Baseline**: Minimal restrictions
- **Restricted**: Most restrictive, follows pod hardening best practices

</details>

### Question 6

You have a database application that requires persistent storage and stable network identity. Which workload type should you use?

A. Deployment  
B. StatefulSet  
C. DaemonSet  
D. Job  

**Answer: B**

<details>
<summary>Explanation</summary>

Databases require:

- Stable network identity (predictable pod names)
- Persistent storage that follows the pod
- Ordered deployment and scaling

StatefulSets provide all of these. Deployments are for stateless applications.

</details>

### Question 7

What happens to existing pods on a node when you run `kubectl cordon node1`?

A. All pods are immediately evicted  
B. Existing pods continue running; no new pods can be scheduled  
C. Pods are gracefully terminated  
D. The node is removed from the cluster  

**Answer: B**

<details>
<summary>Explanation</summary>

`kubectl cordon` only affects scheduling of new pods. Existing pods remain running. To evict existing pods, you would use `kubectl drain`.

</details>

### Question 8

Which command is used to view logs from a specific container in a pod?

A. `kubectl describe pod <pod-name>`  
B. `kubectl get logs <pod-name>`  
C. `kubectl logs <pod-name>`  
D. `kubectl inspect <pod-name>`  

**Answer: C**

<details>
<summary>Explanation</summary>

`kubectl logs` retrieves container logs. Add `-c <container-name>` for multi-container pods. `kubectl describe` shows events and metadata, not logs.

</details>

### Question 9

What is the purpose of a namespace in Kubernetes?

A. To provide network isolation between pods  
B. To organize and isolate resources within a cluster  
C. To define pod security policies  
D. To manage container images  

**Answer: B**

<details>
<summary>Explanation</summary>

Namespaces provide a way to divide cluster resources between multiple users or projects. They provide scope for names and can have resource quotas. They don't provide network isolation by default (Network Policies do that).

</details>

### Question 10

Which component is responsible for scheduling pods to nodes in a Kubernetes cluster?

A. kubelet  
B. kube-proxy  
C. kube-scheduler  
D. controller-manager  

**Answer: C**

<details>
<summary>Explanation</summary>

The kube-scheduler watches for newly created pods and assigns them to nodes based on resource requirements, constraints, and policies. kubelet runs on nodes and ensures containers are running. kube-proxy handles network rules.

</details>

### Question 11

What kubectl command can you use to modify a deployment's replica count?

A. `kubectl edit deployment <name>`  
B. `kubectl patch deployment <name> -p '{"spec":{"replicas":5}}'`  
C. `kubectl scale deployment <name> --replicas=5`  
D. All of the above  

**Answer: D**

<details>
<summary>Explanation</summary>

All three methods can modify a deployment's replica count:

- `kubectl edit` opens the resource in an editor
- `kubectl patch` applies partial changes
- `kubectl scale` is specifically designed for scaling

</details>

### Question 12

Which kubectl command creates a pod that runs only once and terminates?

A. `kubectl create pod <name> --image=<image>`  
B. `kubectl run <name> --image=<image> --restart=Never`  
C. `kubectl apply -f pod.yaml --once`  
D. `kubectl execute <name> --image=<image>`  

**Answer: B**

<details>
<summary>Explanation</summary>

The `--restart=Never` flag creates a pod that won't be restarted after completion, running only once. Default restart policy is "Always".

</details>

### Question 13

What is the default restart policy for pods in Kubernetes?

A. Never  
B. OnFailure  
C. Always  
D. RestartOnError  

**Answer: C**

<details>
<summary>Explanation</summary>

The default restart policy for pods is "Always", meaning containers will be restarted regardless of exit status. Other options are "OnFailure" and "Never".

</details>

### Question 14

Which resource ensures that a specific number of pod replicas are running at all times?

A. Pod  
B. ReplicaSet  
C. Service  
D. ConfigMap  

**Answer: B**

<details>
<summary>Explanation</summary>

A ReplicaSet ensures that a specified number of pod replicas are running at any given time. Deployments manage ReplicaSets, and ReplicaSets manage pods.

</details>

### Question 15

You need to update a deployment's container image. Which command should you use?

A. `kubectl set image deployment/<name> <container>=<new-image>`  
B. `kubectl update deployment/<name> --image=<new-image>`  
C. `kubectl modify deployment/<name> image=<new-image>`  
D. `kubectl change deployment/<name> --image=<new-image>`  

**Answer: A**

<details>
<summary>Explanation</summary>

`kubectl set image` is the imperative command to update container images. Other commands listed don't exist in kubectl.

</details>

### Question 16

What is the purpose of labels in Kubernetes?

A. To provide human-readable names for resources  
B. To organize and select groups of objects  
C. To define resource quotas  
D. To configure network policies  

**Answer: B**

<details>
<summary>Explanation</summary>

Labels are key-value pairs attached to objects for organization and selection. Selectors use labels to identify groups of resources. They're essential for Services, Deployments, and other controllers.

</details>

### Question 17

Which file format is primarily used for Kubernetes resource definitions?

A. JSON only  
B. XML  
C. YAML or JSON  
D. TOML  

**Answer: C**

<details>
<summary>Explanation</summary>

Kubernetes accepts both YAML and JSON for resource definitions. YAML is more commonly used because it's more human-readable and supports comments.

</details>

### Question 18

What is a pod in Kubernetes?

A. A single container  
B. The smallest deployable unit that can contain one or more containers  
C. A group of nodes  
D. A storage volume  

**Answer: B**

<details>
<summary>Explanation</summary>

A pod is the smallest and simplest Kubernetes object. It can contain one or more tightly coupled containers that share storage and network resources.

</details>

### Question 19

Which kubectl command displays detailed information about a specific resource?

A. `kubectl get <resource> <name> -o wide`  
B. `kubectl inspect <resource> <name>`  
C. `kubectl describe <resource> <name>`  
D. `kubectl info <resource> <name>`  

**Answer: C**

<details>
<summary>Explanation</summary>

`kubectl describe` provides detailed information about a resource, including events, conditions, and relationships. `kubectl get -o wide` shows additional columns but less detail than describe.

</details>

### Question 20

What is the purpose of a Service in Kubernetes?

A. To provide persistent storage for pods  
B. To expose pods to network traffic  
C. To schedule pods on nodes  
D. To manage pod lifecycle  

**Answer: B**

<details>
<summary>Explanation</summary>

A Service provides stable networking for pods. It creates a stable IP address and DNS name and load balances traffic across matching pods. Services abstract pod IP addresses which change when pods are recreated.

</details>

### Question 21

Which Pod Security Standard should be used for security-sensitive workloads that require maximum isolation?

A. Privileged  
B. Baseline  
C. Restricted  
D. Enhanced  

**Answer: C**

<details>
<summary>Explanation</summary>

The Restricted Pod Security Standard is the most secure, enforcing pod hardening best practices. It prevents privilege escalation, requires running as non-root, and restricts capabilities.

</details>

### Question 22

What command removes a taint from a node?

A. `kubectl taint nodes <node> key:NoSchedule-`  
B. `kubectl untaint nodes <node> key`  
C. `kubectl remove taint <node> key`  
D. `kubectl delete taint <node> key`  

**Answer: A**

<details>
<summary>Explanation</summary>

The minus sign (-) at the end removes a taint. Format: `kubectl taint nodes <node> <key>:<effect>-`

</details>

### Question 23

Which Kubernetes object stores non-sensitive configuration data as key-value pairs?

A. Secret  
B. ConfigMap  
C. Volume  
D. PersistentVolume  

**Answer: B**

<details>
<summary>Explanation</summary>

ConfigMaps store non-sensitive configuration data as key-value pairs or files. Secrets are for sensitive data. Both can be consumed as environment variables or mounted as files.

</details>

### Question 24

What is the primary role of kubelet?

A. Schedule pods to nodes  
B. Manage the API server  
C. Ensure containers are running on a node  
D. Route network traffic  

**Answer: C**

<details>
<summary>Explanation</summary>

kubelet is the node agent that ensures containers are running as specified in pod specifications. It communicates with the API server and manages container runtime.

</details>

### Question 25

Which command displays all pods in all namespaces?

A. `kubectl get pods`  
B. `kubectl get pods --all`  
C. `kubectl get pods --all-namespaces`  
D. `kubectl get pods -n *`  

**Answer: C**

<details>
<summary>Explanation</summary>

The `--all-namespaces` flag (or `-A`) shows resources across all namespaces. Without it, kubectl only shows resources in the current namespace.

</details>

### Question 26

What happens when a pod's liveness probe fails?

A. The pod is marked as unhealthy but continues running  
B. The container is restarted  
C. The pod is deleted  
D. Nothing, it's just a warning  

**Answer: B**

<details>
<summary>Explanation</summary>

When a liveness probe fails repeatedly, Kubernetes restarts the container. Readiness probes stop traffic but don't restart. Startup probes protect slow-starting containers.

</details>

### Question 27

Which kubectl command can be used to execute a command inside a running container?

A. `kubectl exec <pod-name> -- <command>`  
B. `kubectl run <pod-name> <command>`  
C. `kubectl execute <pod-name> <command>`  
D. `kubectl ssh <pod-name> <command>`  

**Answer: A**

<details>
<summary>Explanation</summary>

`kubectl exec` executes commands in a running container. The `--` separates kubectl arguments from the command to execute. Add `-it` for interactive terminal.

</details>

---

## Section 2: Container Orchestration (Questions 28-44)

### Question 28

What is the purpose of a DaemonSet?

A. To run a copy of a pod on all (or some) nodes in the cluster  
B. To ensure a specified number of pod replicas are running  
C. To run pods that perform batch jobs  
D. To manage stateful applications  

**Answer: A**

<details>
<summary>Explanation</summary>

DaemonSets ensure that a pod runs on every node (or selected nodes using node selectors). Common use cases include log collectors, monitoring agents, and storage daemons.

</details>

### Question 29

Which Container Runtime Interface (CRI) compliant runtime can be used with Kubernetes?

A. containerd  
B. CRI-O  
C. Docker Engine (via dockershim)  
D. Both A and B  

**Answer: D**

<details>
<summary>Explanation</summary>

Both containerd and CRI-O implement the Container Runtime Interface and can be used with Kubernetes. Docker Engine requires dockershim (deprecated) or containerd.

</details>

### Question 30

What type of storage is best suited for a StatefulSet running a database?

A. emptyDir  
B. PersistentVolume with ReadWriteOnce access mode  
C. hostPath  
D. ConfigMap  

**Answer: B**

<details>
<summary>Explanation</summary>

StatefulSets require persistent storage that survives pod rescheduling. PersistentVolumes with ReadWriteOnce provide dedicated storage per pod. emptyDir is ephemeral and deleted when pods are removed.

</details>

### Question 31

What is the primary difference between a Deployment and a StatefulSet?

A. Deployments are for stateless apps; StatefulSets provide stable network identity and persistent storage  
B. StatefulSets cannot be scaled  
C. Deployments require more resources  
D. StatefulSets do not support rolling updates  

**Answer: A**

<details>
<summary>Explanation</summary>

Key differences:

- Deployments: stateless, interchangeable pods, shared storage
- StatefulSets: stateful, unique pod identities (pod-0, pod-1), dedicated persistent volumes, ordered operations

</details>

### Question 32

Which network policy type controls incoming traffic to pods?

A. Egress  
B. Ingress  
C. Both A and B  
D. Route  

**Answer: B**

<details>
<summary>Explanation</summary>

Network Policies have two types:

- **Ingress**: Controls incoming traffic TO pods
- **Egress**: Controls outgoing traffic FROM pods

A policy can define both.

</details>

### Question 33

What is the purpose of a sidecar container?

A. To replace the main container when it fails  
B. To extend or enhance the functionality of the main container  
C. To schedule the main container  
D. To monitor node health  

**Answer: B**

<details>
<summary>Explanation</summary>

Sidecar containers run alongside the main container in the same pod, sharing network and storage. Common uses: logging, monitoring, proxies, service mesh. They enhance without replacing the main container.

</details>

### Question 34

Which volume type is suitable for sharing files between containers in the same pod?

A. PersistentVolume  
B. hostPath  
C. emptyDir  
D. nfs  

**Answer: C**

<details>
<summary>Explanation</summary>

emptyDir is a temporary volume that exists as long as the pod runs. It's shared between all containers in the pod. When the pod is removed, the emptyDir is deleted. Perfect for scratch space or sharing files between containers.

</details>

### Question 35

What does HPA (Horizontal Pod Autoscaler) scale based on?

A. Node capacity only  
B. CPU utilization, memory, or custom metrics  
C. Network traffic only  
D. Storage usage  

**Answer: B**

<details>
<summary>Explanation</summary>

HPA can scale based on:

- CPU utilization
- Memory utilization
- Custom metrics (from applications or external systems)
- Multiple metrics simultaneously

</details>

### Question 36

Can HPA be used with a DaemonSet?

A. Yes, it's recommended  
B. No, because DaemonSets run one pod per node by design  
C. Yes, but only for CPU metrics  
D. No, DaemonSets don't support scaling  

**Answer: B**

<details>
<summary>Explanation</summary>

DaemonSets maintain one pod per node (or selected nodes). Horizontal scaling doesn't make sense for DaemonSets since you can't have multiple pods of the same DaemonSet on one node.

</details>

### Question 37

What scheduler task is NOT a primary responsibility of the Kubernetes scheduler?

A. Selecting which node a pod should run on  
B. Monitoring pod health  
C. Considering resource requirements when placing pods  
D. Respecting node taints and pod tolerations  

**Answer: B**

<details>
<summary>Explanation</summary>

The scheduler assigns pods to nodes. It doesn't monitor pod health (kubelet does that via probes). Scheduler responsibilities:

- Select nodes for pods
- Consider resource requirements
- Respect taints, tolerations, and affinity rules

</details>

### Question 38

Which resource is used to store sensitive information like passwords?

A. ConfigMap  
B. Secret  
C. Volume  
D. Environment variables only  

**Answer: B**

<details>
<summary>Explanation</summary>

Secrets are designed to store sensitive information like passwords, OAuth tokens, and SSH keys. While not encrypted by default, they're more secure than ConfigMaps and can be encrypted at rest with proper configuration.

</details>

### Question 39

How are Secrets stored in Kubernetes by default?

A. Encrypted at rest automatically  
B. Base64 encoded (not encrypted)  
C. Plain text  
D. Hashed with SHA-256  

**Answer: B**

<details>
<summary>Explanation</summary>

By default, Secrets are only base64 encoded, NOT encrypted. Base64 is encoding, not encryption—anyone with access to etcd can decode them. Enable encryption at rest in API server configuration for true security.

</details>

### Question 40

You want to ensure that a specific pod only runs on nodes with GPU hardware. What should you use?

A. Pod affinity  
B. Node selector or node affinity  
C. DaemonSet  
D. Taints only  

**Answer: B**

<details>
<summary>Explanation</summary>

To target specific hardware:

- **Node selectors**: Simple label matching (e.g., `gpu=true`)
- **Node affinity**: More expressive rules
- **Taints/tolerations**: Also work but are typically for repelling pods

</details>

### Question 41

What is the correct taint effect to prevent new pods from scheduling but allow existing pods to continue running?

A. NoExecute  
B. NoSchedule  
C. PreferNoSchedule  
D. PreventSchedule  

**Answer: B**

<details>
<summary>Explanation</summary>

Taint effects:

- **NoSchedule**: Prevents new pods from scheduling (existing pods stay)
- **PreferNoSchedule**: Soft version, tries to avoid scheduling
- **NoExecute**: Evicts existing pods and prevents new ones

</details>

### Question 42

Which of the following can trigger a pod eviction?

A. Node running out of resources  
B. Taint with NoExecute effect  
C. kubectl drain command  
D. All of the above  

**Answer: D**

<details>
<summary>Explanation</summary>

Pods can be evicted by:

- Node resource pressure (out of memory, disk)
- Taints with NoExecute effect
- `kubectl drain` command
- API-initiated eviction

</details>

### Question 43

What is the primary purpose of a Service Account in Kubernetes?

A. To allow users to access the cluster  
B. To provide an identity for pods to interact with the Kubernetes API  
C. To manage node authentication  
D. To store user passwords  

**Answer: B**

<details>
<summary>Explanation</summary>

Service Accounts provide an identity for processes running in pods. They allow pods to authenticate with the API server and access cluster resources. Each namespace has a default service account.

</details>

### Question 44

Which workload type is best for running a web application that sends requests to other microservices?

A. StatefulSet  
B. DaemonSet  
C. Deployment  
D. Job  

**Answer: C**

<details>
<summary>Explanation</summary>

Web applications that proxy or send traffic are stateless. They don't need persistent storage or stable identity. Deployments are perfect for stateless applications that can be scaled horizontally.

</details>

---

## Section 3: Cloud Native Application Delivery (Questions 45-53)

### Question 45

What is the primary purpose of ArgoCD?

A. Container image building  
B. GitOps continuous delivery for Kubernetes  
C. Log aggregation  
D. Network routing  

**Answer: B**

<details>
<summary>Explanation</summary>

ArgoCD is a declarative GitOps continuous delivery tool. It monitors Git repositories and automatically synchronizes the desired state to Kubernetes clusters. Perfect for multi-cluster deployments and automated delivery.

</details>

### Question 46

When should you use Helm?

A. To package and deploy Kubernetes applications using templates  
B. To monitor cluster performance  
C. To manage container images  
D. To configure network policies  

**Answer: A**

<details>
<summary>Explanation</summary>

Helm is a package manager for Kubernetes. It uses templates (charts) to define, install, and upgrade Kubernetes applications. Charts can be versioned, shared, and customized with values files.

</details>

### Question 47

What is a Helm chart?

A. A performance monitoring tool  
B. A package of Kubernetes resources  
C. A network topology diagram  
D. A container image registry  

**Answer: B**

<details>
<summary>Explanation</summary>

A Helm chart is a collection of files that describe related Kubernetes resources. It includes templates, default values, and metadata. Charts can be shared via repositories.

</details>

### Question 48

What is the main advantage of GitOps?

A. Faster container startup times  
B. Using Git as the single source of truth for infrastructure and applications  
C. Reduced storage costs  
D. Improved network performance  

**Answer: B**

<details>
<summary>Explanation</summary>

GitOps core principles:

- Git is the source of truth
- Declarative configuration
- Automated synchronization
- Version control for infrastructure
- Audit trail via Git history

</details>

### Question 49

Which deployment strategy involves running two identical production environments (old and new)?

A. Rolling update  
B. Canary deployment  
C. Blue-green deployment  
D. Recreate  

**Answer: C**

<details>
<summary>Explanation</summary>

Blue-green deployment maintains two identical environments:

- Blue: Current production
- Green: New version

Traffic switches completely from blue to green once validated. Enables instant rollback.

</details>

### Question 50

What is the purpose of an Ingress controller?

A. To manage container lifecycle  
B. To provide HTTP/HTTPS routing to services  
C. To schedule pods on nodes  
D. To store application secrets  

**Answer: B**

<details>
<summary>Explanation</summary>

Ingress controllers implement Ingress resources, providing:

- HTTP/HTTPS routing
- Load balancing
- SSL/TLS termination
- Name-based virtual hosting

</details>

### Question 51

What advantage does Gateway API have over traditional Ingress?

A. Faster performance  
B. Lower resource usage  
C. Role-oriented design, multi-protocol support, and better extensibility  
D. Simpler configuration  

**Answer: C**

<details>
<summary>Explanation</summary>

Gateway API advantages over Ingress:

- Role-oriented: Separate resources for different roles
- Multi-protocol: HTTP, HTTPS, TCP, UDP, gRPC
- Extensible: Standardized extension points
- Cross-namespace routing
- Better traffic management (canary, A/B testing)

</details>

### Question 52

Which tool would you use to deploy applications to multiple Kubernetes clusters from a Git repository?

A. Helm  
B. ArgoCD  
C. kubectl  
D. Docker  

**Answer: B**

<details>
<summary>Explanation</summary>

ArgoCD excels at multi-cluster management with Git as the source of truth. It can deploy to multiple clusters from a single Git repository, monitor sync status, and auto-heal configuration drift.

</details>

### Question 53

What is a key benefit of using declarative configuration for Kubernetes resources?

A. Faster execution  
B. Desired state can be version controlled and automatically reconciled  
C. Requires less storage  
D. Works without an API server  

**Answer: B**

<details>
<summary>Explanation</summary>

Declarative configuration (YAML/JSON) describes the desired state. Kubernetes controllers automatically reconcile actual state to match desired state. Benefits: version control, repeatability, auditability.

</details>

---

## Section 4: Cloud Native Architecture (Questions 54-60)

### Question 54

Which CNCF project is used for collecting metrics and monitoring Kubernetes clusters?

A. Fluentd  
B. Prometheus  
C. Envoy  
D. CoreDNS  

**Answer: B**

<details>
<summary>Explanation</summary>

Prometheus is the CNCF standard for metrics collection and monitoring. It collects time-series data, provides a powerful query language (PromQL), and integrates with Grafana for visualization.

</details>

### Question 55

What is the purpose of distributed tracing?

A. To track requests as they flow through microservices  
B. To monitor disk usage  
C. To manage network routing  
D. To schedule container workloads  

**Answer: A**

<details>
<summary>Explanation</summary>

Distributed tracing tracks requests across multiple services, showing:

- Request path through services
- Latency at each hop
- Errors and bottlenecks
- Service dependencies

Tools: Jaeger, Zipkin

</details>

### Question 56

What are "spans" in the context of distributed tracing?

A. Network segments  
B. Individual units of work in a distributed system  
C. Storage volumes  
D. Pod replicas  

**Answer: B**

<details>
<summary>Explanation</summary>

In distributed tracing:

- **Trace**: Complete journey of a request
- **Span**: Individual operation within a trace (e.g., database query, HTTP call)

Spans have start time, duration, and metadata.

</details>

### Question 57

Which of the following is a core principle of cloud-native architecture?

A. Monolithic application design  
B. Manual scaling and deployment  
C. Microservices, containers, and dynamic orchestration  
D. Single point of failure for simplicity  

**Answer: C**

<details>
<summary>Explanation</summary>

Cloud-native principles:

- Microservices architecture
- Containerization
- Dynamic orchestration (Kubernetes)
- Automation and CI/CD
- Resilience and observability
- DevOps culture

</details>

### Question 58

What is the role of the CNCF (Cloud Native Computing Foundation)?

A. To sell cloud computing services  
B. To provide a vendor-neutral home for open-source cloud-native projects  
C. To compete with Kubernetes  
D. To develop proprietary cloud solutions  

**Answer: B**

<details>
<summary>Explanation</summary>

CNCF (Cloud Native Computing Foundation) hosts and nurtures cloud-native open-source projects like Kubernetes, Prometheus, Envoy, and many others. It's vendor-neutral and part of the Linux Foundation.

</details>

### Question 59

Which image pull policy instructs Kubernetes to always pull the container image from the registry?

A. IfNotPresent  
B. Never  
C. Always  
D. OnUpdate  

**Answer: C**

<details>
<summary>Explanation</summary>

Image pull policies:

- **Always**: Pull image every time (latest tags)
- **IfNotPresent**: Pull only if not cached locally (default for specific tags)
- **Never**: Never pull, must exist locally

</details>

### Question 60

You have an application that requires a database with persistent storage and consistent network identity. Which statement is correct?

A. Use a Deployment because it's more flexible  
B. Use a StatefulSet because databases need stable identity and persistent volumes  
C. Use a DaemonSet to ensure the database runs on every node  
D. Use a Job because databases complete their work and exit  

**Answer: B**

<details>
<summary>Explanation</summary>

Databases require:

- Persistent storage (data survives restarts)
- Stable network identity (for replication, clustering)
- Ordered scaling (primary before replicas)

StatefulSets provide all of these guarantees.

</details>
