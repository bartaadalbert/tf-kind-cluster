resource "null_resource" "install_kind" {
  provisioner "local-exec" {
    command      = <<-EOT
      if ! command -v kind &> /dev/null; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
      fi
    EOT
    interpreter  = ["bash", "-c"]
    on_failure   = continue
  }
}


resource "null_resource" "create_cluster" {
  depends_on = [null_resource.install_kind]

  triggers = {
    cluster_name = var.KIND_CLUSTER_NAME
  }
  provisioner "local-exec" {
    command = "echo '${jsonencode({kind = "Cluster", apiVersion = "kind.x-k8s.io/v1alpha4", nodes = local.all_nodes})}' | kind create cluster --name ${self.triggers.cluster_name} --config -"
  }

  provisioner "local-exec" {
    command = "sleep ${var.SLEEP_DURATION}" 
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kind delete cluster --name ${self.triggers.cluster_name}"
  }

}


resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.create_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      if [ "$${TF_PHASE}" = "apply" ]; then
        kind get kubeconfig --name ${var.KIND_CLUSTER_NAME} > ${path.module}/kind-config &&
        KUBECONFIG=${path.module}/kind-config kubectl config use-context kind-${var.KIND_CLUSTER_NAME} &&
        KUBECONFIG=${path.module}/kind-config kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' > ${path.module}/kind-ca &&
        KUBECONFIG=${path.module}/kind-config kubectl config view --raw --minify --flatten -o jsonpath='{.users[0].user.client-certificate-data}' > ${path.module}/kind-crt &&
        KUBECONFIG=${path.module}/kind-config kubectl config view --raw --minify --flatten -o jsonpath='{.users[0].user.client-key-data}' > ${path.module}/kind-client-key &&
        KUBECONFIG=${path.module}/kind-config kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.server}' > ${path.module}/kind-endpoint
      fi
    EOT
    interpreter = ["bash", "-c"]
    on_failure  = continue
  }
}



resource "null_resource" "get_clusters" {
  depends_on = [null_resource.create_cluster]

  
  provisioner "local-exec" {
    command = "kubectl get nodes --context kind-${var.KIND_CLUSTER_NAME}"
  }
}

resource "null_resource" "label_nodes" {
  depends_on = [null_resource.create_cluster]
  count      = var.NUM_WORKERS

  provisioner "local-exec" {
    command = "kubectl label nodes ${count.index == 0 ? "${var.KIND_CLUSTER_NAME}-worker" : "${var.KIND_CLUSTER_NAME}-worker${count.index + 1}"} node-role.kubernetes.io/worker="
  }
}

resource "null_resource" "label_masters" {
  depends_on = [null_resource.create_cluster]
  count      = var.NUM_MASTERS

  provisioner "local-exec" {
    command = "kubectl label nodes ${count.index == 0 ? "${var.KIND_CLUSTER_NAME}-control-plane" : "${var.KIND_CLUSTER_NAME}-control-plane${count.index + 1}"} node-role.kubernetes.io/master="
  }
}







