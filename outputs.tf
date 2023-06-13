output "kubeconfig" {
  description = "The kubeconfig for the created cluster."
  value       = "${path.module}/kind-config"
}

output "client_key" {
  value = null_resource.get_kubeconfig.*.triggers.client_key[0]
}

output "ca" {
  value = null_resource.get_kubeconfig.*.triggers.ca[0]
}

output "crt" {
  value = null_resource.get_kubeconfig.*.triggers.crt[0]
}

output "endpoint" {
  value = null_resource.get_kubeconfig.*.triggers.endpoint[0]
}