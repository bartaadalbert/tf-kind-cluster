output "kubeconfig" {
  description = "The kubeconfig for the created cluster."
  value       = "${path.module}/kind-config"
}

output "client_key" {
  value = file("${path.module}/kind-client-key")
}

output "ca" {
  value = file("${path.module}/kind-ca")
}

output "crt" {
  value = file("${path.module}/kind-crt")
}

output "endpoint" {
  value = file("${path.module}/kind-endpoint")
}