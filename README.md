# Kind Cluster Terraform Module

This module provisions a local Kubernetes cluster using Kind.

## Inputs:

- `KIND_CLUSTER_NAME`: The name of the Kind cluster to be created.
- `NUM_MASTERS`: Number of master nodes.
- `NUM_WORKERS`: Number of worker nodes.

## Outputs:

- `kubeconfig`: The kubeconfig for the created cluster.