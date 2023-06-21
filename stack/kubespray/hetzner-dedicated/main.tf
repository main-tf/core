
variable "network_zone" {

}

variable "ip_range" {
  description = "The IP range of dedicated servers subnet in cloud network"
}

variable "vswitch_id" {
  type = number
}

variable "vlan_id" {
  type = number
}

variable "servers" {
  default = []
}

resource "hcloud_network_subnet" "dedicated" {
  network_id   = var.sys_nodes.network_id
  type         = "vswitch"
  network_zone = var.network_zone
  ip_range     = var.ip_range
  vswitch_id   = var.vswitch_id
}

data "hcloud_network" "k8s" {
  id = var.sys_nodes.network_id
}

data "remote_file" "netplan" {
  count = length(var.servers)
  conn {
    host        = var.servers[count.index].public_ip
    port        = 22
    user        = "root"
    private_key = data.vault_generic_secret.cluster.data.ssh_private_key
  }
  path = "/etc/netplan/01-netcfg.yaml"
}

locals {
  netplans = [for np in data.remote_file.netplan : yamldecode(np.content)]
  interfaces = [
    for np in local.netplans : keys(np.network.ethernets)[0]
  ]

  vlans = [for i, s in var.servers : {
    network = {
      renderer = "networkd"
      version  = 2
      vlans = {
        "${local.interfaces[i]}.${var.vlan_id}" = {
          id        = var.vlan_id
          link      = local.interfaces[i]
          mtu       = 1400
          addresses = ["${s.private_ip}/24"]
          routes = [
            {
              to  = data.hcloud_network.k8s.ip_range
              via = cidrhost(var.ip_range, 1)
            }
          ]
        }
      }
    }
  }]

  nodes = merge(var.sys_nodes.nodes, { for s in var.servers : s.name => merge({
    private_ip = s.private_ip
    public_ip  = s.public_ip
    node_type  = "static-worker"
    name       = s.name
    pool_name  = "dedicated"
    },
    lookup(s, "node_taints", false) != false ? { node_taints = s.node_taints } : {},
    lookup(s, "node_labels", false) != false ? { node_labels = s.node_labels } : {},
  ) })
}

resource "remote_file" "vlans" {
  count = length(var.servers)
  conn {
    host        = var.servers[count.index].public_ip
    port        = 22
    user        = "root"
    private_key = data.vault_generic_secret.cluster.data.ssh_private_key
  }
  connection {
    host        = var.servers[count.index].public_ip
    port        = 22
    user        = "root"
    private_key = data.vault_generic_secret.cluster.data.ssh_private_key
  }
  path    = "/etc/netplan/10-vlan.yaml"
  content = yamlencode(local.vlans[count.index])

  provisioner "remote-exec" {
    inline = [
      "netplan apply",
      "useradd -m -s /bin/bash -G sudo ubuntu",
      "echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu",
      "mkdir -p /home/ubuntu/.ssh",
      "echo '${data.vault_generic_secret.cluster.data.ssh_public_key}' > /home/ubuntu/.ssh/authorized_keys",
      "chown -R ubuntu:ubuntu /home/ubuntu/.ssh",
      "chmod 700 /home/ubuntu/.ssh",
      "chmod 600 /home/ubuntu/.ssh/authorized_keys",
    ]
  }
}

output "nodes" {
  value = local.nodes
}
