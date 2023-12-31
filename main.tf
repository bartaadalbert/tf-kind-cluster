resource "null_resource" "install_kind" {
  provisioner "local-exec" {
    command = <<EOT
      # Define color variables
      SUCCESS_COLOR="\e[32m"
      INFO_COLOR="\e[36m"
      ERROR_COLOR="\e[31m"
      RESET_COLOR="\e[0m"

      # Detect the OS and architecture
      OS=$(uname | tr '[:upper:]' '[:lower:]')
      ARCH=$(uname -m)

      echo -e "$INFO_COLOR Operating system detected:$RESET_COLOR $SUCCESS_COLOR $OS$RESET_COLOR"
      echo -e "$INFO_COLOR Architecture detected:$RESET_COLOR $SUCCESS_COLOR $ARCH$RESET_COLOR"

      if [[ "$OS" == "windows"* ]]; then
        echo -e "$ERROR_COLOR This script does not support Windows. Please install Docker and Kind manually.$RESET_COLOR"
        exit 1
      fi

      # Check for Docker installation
      if ! command -v docker &> /dev/null; then
        echo -e "$INFO_COLOR Docker not found. Installing...$RESET_COLOR"
        if [[ "$OS" == "linux" ]]; then
          sudo apt update
          sudo apt install -y docker.io
          sudo usermod -aG docker $USER
          sudo systemctl restart docker
        elif [[ "$OS" == "darwin" ]]; then
          brew install --cask docker
        fi
      else
        echo -e "$SUCCESS_COLOR Docker is installed.$RESET_COLOR"
      fi

      # Check for Kubectl installation
      if ! command -v kubectl &> /dev/null; then
        echo -e "$INFO_COLOR Kubectl not found. Installing...$RESET_COLOR"
        if [[ "$OS" == "linux" ]]; then
          if [[ "$ARCH" == "x86_64" ]]; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          elif [[ "$ARCH" == "aarch64" ]]; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
          fi
        elif [[ "$OS" == "darwin" ]]; then
          if [[ "$ARCH" == "x86_64" ]]; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
          elif [[ "$ARCH" == "aarch64" ]]; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
          fi
        fi
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
      else
        echo -e "$SUCCESS_COLOR Kubectl is installed.$RESET_COLOR"
      fi

      # Check for Kind installation
      if ! command -v kind &> /dev/null; then
        echo -e "$INFO_COLOR Kind not found. Installing...$RESET_COLOR"
        LATEST_KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep -Eo '"tag_name": "[^"]+"' | cut -d'"' -f4)
        if [[ "$ARCH" == "x86_64" ]]; then
          curl -L -o /usr/local/bin/kind \
          "https://github.com/kubernetes-sigs/kind/releases/download/$LATEST_KIND_VERSION/kind-$OS-amd64"
        elif [[ "$ARCH" == "aarch64" ]]; then
          curl -L -o /usr/local/bin/kind \
          "https://github.com/kubernetes-sigs/kind/releases/download/$LATEST_KIND_VERSION/kind-$OS-arm64"
        else
          echo -e "$ERROR_COLOR Unsupported architecture. Please install Kind manually.$RESET_COLOR"
          exit 1
        fi
        chmod +x /usr/local/bin/kind
      else
        echo -e "$SUCCESS_COLOR Kind is installed.$RESET_COLOR"
      fi
    EOT
    interpreter = ["bash", "-c"]
    on_failure  = fail
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
      # Define color variables
      SUCCESS_COLOR="\e[32m"
      INFO_COLOR="\e[36m"
      ERROR_COLOR="\e[31m"
      RESET_COLOR="\e[0m"

      until [ $(kubectl get nodes --no-headers --context kind-${var.KIND_CLUSTER_NAME} | grep -v ' Ready ' | wc -l) -eq 0 ]; do 
        echo -e "$INFO_COLOR Waiting for all nodes to become ready... $RESET_COLOR" 
        sleep 2
      done
      echo -e "$SUCCESS_COLOR All nodes are ready. Cluster is now available. $RESET_COLOR"

      echo -e "$INFO_COLOR List of clusters: $RESET_COLOR" 
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
      # Define color variables
      SUCCESS_COLOR="\e[32m"
      INFO_COLOR="\e[36m"
      RESET_COLOR="\e[0m"

      until [ -f "${path.module}/kind-config" ]; do
        echo -e "$INFO_COLOR Waiting for kind-config be ready...$RESET_COLOR"
        sleep 2
      done
      echo -e "$SUCCESS_COLOR kind-config is ready...$RESET_COLOR"
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







