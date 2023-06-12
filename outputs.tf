output "kubeconfig" {
  description = "The kubeconfig for the created cluster."
  value       = "${path.module}/kind-config"
}