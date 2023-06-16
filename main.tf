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
    when    = destroy
    command = "kind delete cluster --name ${self.triggers.cluster_name}"
  }

}

resource "null_resource" "cluster_ready_check" {
  count = var.WAIT_FOR_READY ? 1 : 0

  depends_on = [null_resource.create_cluster]

  provisioner "local-exec" {
    command = <<-EOC
      until [ $(kubectl get nodes --no-headers --context kind-${var.KIND_CLUSTER_NAME} | grep -v ' Ready ' | wc -l) -eq 0 ]; do 
        echo 'Waiting for all nodes to become ready...'
        sleep 2
      done

      echo 'All nodes are ready. Cluster is now available.'

      echo 'List of clusters:'
      kind get clusters
    EOC
  }
}


resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.create_cluster]

  provisioner "local-exec" {
    command = "kind get kubeconfig --name ${var.KIND_CLUSTER_NAME} > ${path.module}/kind-config"
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
      until [ -f "${path.module}/kind-config" ]; do
        echo 'Waiting for kind-config be ready...'
        sleep 2
      done
    EOT
    command = "kubectl get nodes --context kind-${var.KIND_CLUSTER_NAME}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/kind-config ${path.module}/kind-ca* ${path.module}/kind-crt* ${path.module}/kind-client-key* ${path.module}/kind-endpoint"
  }
}


resource "null_resource" "extract_kubeconfig_values" {
  depends_on = [null_resource.get_kubeconfig]

  provisioner "local-exec" {
    command = <<-EOT
      if kind get clusters | grep -q "${var.KIND_CLUSTER_NAME}"; then
        if [ -f "${path.module}/kind-config" ]; then
          KUBECONFIG=${path.module}/kind-config kubectl config use-context kind-${var.KIND_CLUSTER_NAME} &&
          KUBECONFIG=${path.module}/kind-config kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode > ${path.module}/kind-ca.crt &&
          KUBECONFIG=${path.module}/kind-config kubectl config view --raw --minify --flatten -o jsonpath='{.users[0].user.client-certificate-data}' | base64 --decode > ${path.module}/kind-crt.crt &&
          KUBECONFIG=${path.module}/kind-config kubectl config view --raw --minify --flatten -o jsonpath='{.users[0].user.client-key-data}' | base64 --decode > ${path.module}/kind-client-key.pem &&
          KUBECONFIG=${path.module}/kind-config kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.server}' > ${path.module}/kind-endpoint
        else
          echo "${path.module}/kind-config does not exist."
        fi
      else
        echo "Cluster ${var.KIND_CLUSTER_NAME} does not exist."
      fi
    EOT
    interpreter = ["bash", "-c"]
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







