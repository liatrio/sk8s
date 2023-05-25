# IAM Roles and Policies
In addition to the network requirements outlined above, a set of IAM policies must be attached to the EKS cluster being deployed to manage the lifecycle of the worker nodes and pods being scheduled on them. In order for the cluster to manage those resources on our behalf we must attach the following:
* arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
* arn:aws:iam::aws:policy/AmazonEKSServicePolicy

The `AmazonEKSClusterPolicy` allows EKS to modify the EC2 instances that make up the node groups so that they can register themselves to the cluster. It also allows the cluster to manage auto-scaling and elastic load balancing of services. The `AmazonEKSServicePolicy` allows it to update the Kubernetes version during a planned upgrade, enable private endpoint networking for its API server, log events for the control plane, etc.

Worker nodes require a separate set of policies to operate, and they are different for managed node groups and Fargate. For managed node groups, three additional policies must be applied to the IAM role governing access to AWS services:
* arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
* arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
* arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

The `AmazonEKSWorkerNodePolicy` is necessary to accurately identify the node joining the cluster based on its volume and network information. The `AmazonEKS_CNI_Policy` permits the creation of elastic network interfaces as well as the allocation of IP addresses for pods scheduled to run on the cluster. Pulling images from ECR onto the worker nodes requires read-only permissions to the container registries for the individual applications, and is granted by the `AmazonEC2ContainerRegistryReadOnly` policy.
