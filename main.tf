resource "null_resource" "install_kind" {
  provisioner "local-exec" {
    command      = <<-EOT
      # Detect the OS and architecture
      OS=$(uname | tr '[:upper:]' '[:lower:]')
      ARCH=$(uname -m)

      echo "Operating system detected: $OS"
      echo "Architecture detected: $ARCH"

      if [[ "$OS" == "windows"* ]]; then
        echo "This script does not support Windows. Please install Docker and Kind manually."
        exit 1
      fi

      # Check for Docker installation
      if ! command -v docker &> /dev/null; then
        echo "Docker not found. Installing..."
        if [[ "$OS" == "linux" ]]; then
          sudo apt-get update
          sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        elif [[ "$OS" == "darwin" ]]; then
          brew install --cask docker
        fi
      else
        echo "Docker is installed."
      fi

      # Check for Kind installation
      if ! command -v kind &> /dev/null; then
        echo "Kind not found. Installing..."
        if [[ "$ARCH" == "x86_64" ]]; then
          curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-$OS-amd64
        elif [[ "$ARCH" == "aarch64" ]]; then
          curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-$OS-arm64
        else
          echo "Unsupported architecture. Please install Kind manually."
          exit 1
        fi
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
      else
        echo "Kind is installed."
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
  depends_on = [null_resource.create_cluster,null_resource.cluster_ready_check]

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
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/kind-config"
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







