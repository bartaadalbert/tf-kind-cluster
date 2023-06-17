Terraform KIND Cluster Module

This Terraform module automates the creation of a Kubernetes IN Docker (KIND) cluster. It not only handles the installation of KIND (if not already installed), but also configures and creates a cluster with the desired number of worker and master nodes. Each node in the cluster is labeled accordingly, allowing for fine-grained control and scheduling of workloads.
Prerequisites

    Terraform 0.13 and later.
    Docker must be installed.

Usage

Here's a basic example of how to use this module in your own Terraform script:

```hcl
module "kind_cluster" {
  source            = "github.com/bartaadalbert/tf-kind-cluster"
  KIND_CLUSTER_NAME = "my-kind-cluster"
  NUM_MASTERS       = 1
  NUM_WORKERS       = 2
}

Replace "my-kind-cluster", 1, and 2 with your desired KIND cluster name, number of master nodes, and number of worker nodes, respectively.

Additional parameters like SLEEP_DURATION and WAIT_FOR_READY can also be modified to suit your needs.

The module produces an output kubeconfig that you can use to interact with your KIND cluster.
Variables

This module accepts the following variables:

    KIND_CLUSTER_NAME: Name of the KIND cluster to create.
    NUM_MASTERS: Number of master nodes in the cluster.
    NUM_WORKERS: Number of worker nodes in the cluster.
    SLEEP_DURATION: The duration to sleep after creating the cluster. Default value is 0.
    WAIT_FOR_READY: Whether to wait for the cluster to be ready before continuing. Default value is true.

Outputs

This module has the following outputs:

    kubeconfig: The kubeconfig for the created cluster.

Node Labels

The module labels each node in the cluster according to their role (master or worker). This labeling allows for more precise scheduling of workloads and resources. The labels assigned are node-role.kubernetes.io/master for master nodes and node-role.kubernetes.io/worker for worker nodes.
Example

Define your variables:

variable "KIND_CLUSTER_NAME" {
  description = "The name of the KIND cluster"
  default     = "my-kind-cluster"
}

variable "NUM_MASTERS" {
  description = "Number of master nodes"
  default     = 1
}

variable "NUM_WORKERS" {
  description = "Number of worker nodes"
  default     = 2
}

Use the module with the defined variables:

module "kind_cluster" {
  source            = "github.com/bartaadalbert/tf-kind-cluster"
  KIND_CLUSTER_NAME = var.KIND_CLUSTER_NAME
  NUM_MASTERS       = var.NUM_MASTERS
  NUM_WORKERS       = var.NUM_WORKERS
}

Contributing

If you find any issues or have suggestions for improvements, feel free to open an issue or submit a pull request.

Modify the draft as per your project's requirements.