output "kubeconfig" {
  description = "The kubeconfig for the created cluster."
  value       = "${path.module}/kind-config"
}

output "client_key" {
  description = "The client key for the created cluster."
  value       = "${path.module}/kind-client-key"
}

output "ca" {
  description = "The CA certificate for the created cluster."
  value       = "${path.module}/kind-ca"
}

output "crt" {
  description = "The client certificate for the created cluster."
  value       = "${path.module}/kind-crt"
}

output "endpoint" {
  description = "The endpoint for the created cluster."
  default     = ""
  value       = "${path.module}/kind-endpoint"
}
