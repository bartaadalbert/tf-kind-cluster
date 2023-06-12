variable "KIND_CLUSTER_NAME" {
  description = "The name of the Kind cluster will be used like you explain it."
  type        = string
  default     = "mykindcluster"
}

variable "NUM_MASTERS" {
  description = "Number of master nodes."
  type        = number
  default     = 1
}

variable "NUM_WORKERS" {
  description = "Number of worker nodes."
  type        = number
  default     = 2
}
