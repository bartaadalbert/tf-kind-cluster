locals {
  master_nodes = [for i in range(var.NUM_MASTERS) : { role = "control-plane" }]
  worker_nodes = [for i in range(var.NUM_WORKERS) : { role = "worker${i+1}" }]
  all_nodes    = concat(local.master_nodes, local.worker_nodes)
}
