output "kubeconfig" {
  description = "The kubeconfig for the created cluster."
  value       = fileexists("${path.module}/kind-config") ? file("${path.module}/kind-config") : "File not found"
}

output "client_key" {
  description = "The client key for the created cluster."
  value       = fileexists("${path.module}/kind-client-key") ? file("${path.module}/kind-client-key") : "File not found"
  sensitive   = true
}

output "ca" {
  description = "The CA certificate for the created cluster."
  value       = fileexists("${path.module}/kind-ca") ? file("${path.module}/kind-ca") : "File not found"
}

output "crt" {
  description = "The client certificate for the created cluster."
  value       = fileexists("${path.module}/kind-crt") ? file("${path.module}/kind-crt") : "File not found"
}

output "endpoint" {
  description = "The endpoint for the created cluster."
  value       = fileexists("${path.module}/kind-endpoint") ? file("${path.module}/kind-endpoint") : "File not found"
}
