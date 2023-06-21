variable "hcloud" {

}


module "kubernetes" {
  # source = "git::https://github.com/kubernetes-sigs/kubespray.git//contrib/terraform/hetzner/modules/kubernetes-cluster?ref=v2.22.1"
  source = "./modules/kubernetes-cluster"

  prefix = local.stackd.cluster_name

  zone = var.hcloud.zone

  machines = local.machines

  #only for flatcar
  #ssh_private_key_path = var.ssh_private_key_path

  ssh_public_keys = [data.vault_generic_secret.cluster.data.ssh_public_key]
  network_zone    = var.hcloud.network_zone

  ssh_whitelist        = var.hcloud.ssh_whitelist
  api_server_whitelist = var.hcloud.api_server_whitelist
  nodeport_whitelist   = var.hcloud.nodeport_whitelist
  ingress_whitelist    = var.hcloud.ingress_whitelist
  firewalls            = var.hcloud.firewalls

  providers = {
    hcloud = hcloud
  }
}

#
# Generate ansible inventory
#

locals {


  machines = { for m in flatten([for pool_name, pool in var.hcloud.pools : [for i in range(1, pool.size + 1) : merge({
    name      = "${pool_name}-${i}"
    node_type = lookup(pool, "control_plain", false) ? "master" : "worker"
    size      = pool.node_size
    image     = var.hcloud.image
    pool_name = pool_name
    }, lookup(pool, "node_taints", false) != false ? { node_taints = pool.node_taints } : {},
    lookup(pool, "node_labels", false) != false ? { node_labels = pool.node_labels } : {},
  )]]) : m.name => m }



  k8s_nodes = merge(module.kubernetes.master_ip_addresses, module.kubernetes.worker_ip_addresses)

  nodes = { for name, machine in local.machines : name => merge(machine, lookup(local.k8s_nodes, "${local.stackd.cluster_name}-${name}", {}), {
    name = "${local.stackd.cluster_name}-${name}"
  }) }


}

output "nodes" {
  value = local.nodes
}

output "cluster_private_network_cidr" {
  value = module.kubernetes.cluster_private_network_cidr
}

output "network_id" {
  value = module.kubernetes.network_id
}

/*
resource "null_resource" "inventories" {
  provisioner "local-exec" {
    command = "echo '${local.inventory}' > ${var.inventory_file}"
  }

  triggers = {
    template = local.inventory
  }
}
*/