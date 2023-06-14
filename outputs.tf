output "kubeconfig" {
  description = "The kubeconfig for the created cluster."
  value       = fileexists("${path.module}/kind-config") ? file("${path.module}/kind-config") : "File not found"
}

output "client_key" {
  description = "The client key for the created cluster."
  value       = fileexists("${path.module}/kind-client-key.pem") ? file("${path.module}/kind-client-key.pem") : "File not found"
  sensitive   = true
}

output "ca" {
  description = "The CA certificate for the created cluster."
  value       = fileexists("${path.module}/kind-ca.crt") ? file("${path.module}/kind-ca.crt") : "File not found"
}

output "crt" {
  description = "The client certificate for the created cluster."
  value       = fileexists("${path.module}/kind-crt.crt") ? file("${path.module}/kind-crt.crt") : "File not found"
}

output "endpoint" {
  description = "The endpoint for the created cluster."
  value       = fileexists("${path.module}/kind-endpoint") ? file("${path.module}/kind-endpoint") : "https://127.0.0.1:45141"
}
