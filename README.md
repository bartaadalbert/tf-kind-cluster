Kind Cluster Terraform Module

This Terraform module is designed to provision a local Kubernetes cluster using Kind (Kubernetes in Docker). The key features of the module include:

    Provisioning a Kind cluster with a configurable number of master and worker nodes.
    An optional waiting functionality until all nodes in the cluster are in the ready state before the module completes.
    Generating certificate files for accessing the created cluster.

Inputs

    KIND_CLUSTER_NAME: The name of the Kind cluster to be created. This name will be used as the context in your kubeconfig file and must be unique if you are creating multiple clusters.
    NUM_MASTERS: Number of master nodes to be created in the cluster. Master nodes host the control plane components of a Kubernetes cluster, such as the API server, controller manager, and scheduler.
    NUM_WORKERS: Number of worker nodes to be created in the cluster. Worker nodes run your applications and services.
    WAIT_FOR_READY: (Optional) A boolean value to indicate whether the module should wait until all nodes in the cluster are in a ready state before it completes. This can be useful if you have other resources or modules that depend on the cluster being fully ready before they can proceed. The default value is true.

Outputs

    client_key: The client key for the created cluster. This is used to authenticate with the cluster.
    ca: The Certificate Authority (CA) certificate for the created cluster. This is used to validate the server certificate.
    crt: The client certificate for the created cluster. This is used along with the client key to authenticate with the cluster.
    endpoint: The endpoint (API server URL) for the created cluster. This is used to communicate with the cluster.


## Usage

Use the module in your Terraform code as shown below:

```hcl
module "kind_cluster" {
  source            = "github.com/bartaadalbert/tf-kind-cluster?ref=cert"
  KIND_CLUSTER_NAME = "my-cluster"
  NUM_MASTERS       = 1
  NUM_WORKERS       = 2
}

You should replace "my-cluster", 1, and 2 with your desired KIND cluster name, the number of master nodes, and the number of worker nodes, respectively.
Variables

    KIND_CLUSTER_NAME: Name of the KIND cluster to create. This value is required.
    NUM_MASTERS: Number of master nodes in the cluster. This value is required.
    NUM_WORKERS: Number of worker nodes in the cluster. This value is required.

You can also use a variables.tf file or pass these variables in using Terraform's -var command-line argument.
Requirements

    Terraform v0.13+
    Docker

Example

Here is a more detailed example of how you can use this module in a project:

Firstly, define your variables:
```hcl
variable "KIND_CLUSTER_NAME" {
  description = "The name of your KIND cluster"
  type        = string
  default     = "my-cluster"
}

variable "NUM_MASTERS" {
  description = "The number of master nodes in the cluster"
  type        = number
  default     = 1
}

variable "NUM_WORKERS" {
  description = "The number of worker nodes in the cluster"
  type        = number
  default     = 2
}

```hcl
module "kind_cluster" {
  source            = "github.com/bartaadalbert/tf-kind-cluster?ref=cert"
  KIND_CLUSTER_NAME = var.KIND_CLUSTER_NAME
  NUM_MASTERS       = var.NUM_MASTERS
  NUM_WORKERS       = var.NUM_WORKERS
}

Contributing

If you find any issues or opportunities for improving this module, feel free to create an issue or a pull request.

Feel free to adjust this draft as needed to better fit your project's requirements.

