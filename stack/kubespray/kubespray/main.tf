
# output nodes {
#     value = var.sys_nodes.nodes
# }

variable kubespray_path {}

variable playbook {
    default = "cluster.yml"
}
variable playbook_tags {
    default = ""
}

variable kubespray_vars {
    default = {}
}

variable playbook_vars {
    default = {}
}

locals {

    playbook_tags = var.playbook_tags != "" ? "--tags=${var.playbook_tags}" : ""
    playbook_vars = join(" ", [for k, v in var.playbook_vars : "-e ${k}=${v}"])

    command = <<EOC
    ansible-playbook -i ${abspath("${path.module}/inventory.yaml")} \
        ${var.playbook} -b -vv --private-key ${abspath("${path.module}/ssh_key")} \
        ${local.playbook_tags} ${local.playbook_vars}
    EOC

    nodes = [ for name, node in var.sys_nodes.nodes : node]
    masters = [ for name, node in var.sys_nodes.nodes : node if node.node_type == "master"]
    kubeconfig_file = abspath("${path.module}/artifacts/admin.conf")
    kubeconfig      = data.local_file.kubeconfig.content
    _kd = yamldecode(local.kubeconfig)
    kubeconfig_data = merge(local._kd, {
        clusters = [merge(local._kd["clusters"][0], {
            cluster = merge(local._kd["clusters"][0]["cluster"], {
                server = "https://${local.masters[0].public_ip}:6443"
            })
        })]
    })

    inventory = {
        all = {
            vars = merge(var.kubespray_vars, {
                artifacts_dir = abspath("${path.module}/artifacts")
                cluster_name= "${local.stackd.cluster}.local"
                kubeconfig_localhost = true                
                kube_proxy_mode = "iptables"
                calico_ipip_mode = "Always"
                calico_vxlan_mode = "Never"
                calico_network_backend = "bird"
            })
            hosts = {for idx, node in local.nodes : node.name => merge({
                ansible_host = node.public_ip
                ansible_user = "ubuntu"
                ip = node.private_ip
                etcd_member_name = node.node_type == "master" ? "etcd${idx+1}" : null
                node_labels = merge({
                    "node.stackd.cloud/type" = node.node_type
                    "node.stackd.cloud/role" = node.node_type == "master" ? "master" : "worker"
                    "node.stackd.cloud/cluster" = local.stackd.cluster
                    "node.stackd.cloud/pool" = node.pool_name
                }, lookup(node, "node_labels", {}))
            }, node.node_type == "static-worker" ? {} : {cloud_provider = "external"},
            lookup(node, "node_taints", false) != false ? {
                node_taints = node.node_taints
            } : {})}
            children = {
                kube_control_plane = { hosts = {for node in local.nodes : node.name => {} if node.node_type == "master"}}
                etcd = { hosts = {for node in local.nodes : node.name => {} if node.node_type == "master"}}
                kube_node = { hosts = {for node in local.nodes : node.name => {} if endswith(node.node_type, "worker")}}
                calico_rr = {      }
                k8s_cluster = {
                    children = {
                        kube_control_plane = {}
                        kube_node = {}
                        calico_rr = {}
                    }
                }
            }
        }
    }
}

resource local_file "inventory" {
    content = yamlencode(local.inventory)
    filename = "${path.module}/inventory.yaml"
}

output inventory_file {
    value = abspath("${path.module}/inventory.yaml")
}

output kubeconfig_file {
    value = local.kubeconfig_file
}

output nodes {
    value = local.nodes
}

output command {
    value = local.command
}

resource local_sensitive_file "ssh_key" {
    content = data.vault_generic_secret.cluster.data["ssh_private_key"]
    filename = "${path.module}/ssh_key"
}

resource "null_resource" "cluster" {
  provisioner "local-exec" {
    command = <<-EOF
      cd ${var.kubespray_path}
      poetry run ${local.command}
    EOF
  }

  triggers = {
    inventory_hash = sha1(jsonencode(local.inventory))
    command_hash = sha1(local.command)
  }
}

data local_file kubeconfig {
    depends_on = [null_resource.cluster]
    filename = local.kubeconfig_file
}

resource "vault_generic_secret" "cluster" {
  depends_on = [null_resource.cluster]
  path       = "kv/${local.stackd.cluster}/cluster"
  data_json = jsonencode(merge(data.vault_generic_secret.cluster.data, {
    kubeconfig             = yamlencode(local.kubeconfig_data)
    client_endpoint        = local.kubeconfig_data["clusters"][0]["cluster"]["server"]
    cluster_ca_certificate = base64decode(local.kubeconfig_data["clusters"][0]["cluster"]["certificate-authority-data"])
    client_certificate     = base64decode(local.kubeconfig_data["users"][0]["user"]["client-certificate-data"])
    client_key             = base64decode(local.kubeconfig_data["users"][0]["user"]["client-key-data"])
  }))
}

