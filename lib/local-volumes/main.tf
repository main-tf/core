variable "local_volumes" {}

locals {
  nodes = { for _, node in var.nodes.nodes : node.name => node }
  volumes = { for b in flatten([for volgroup, vol in var.local_volumes : [
    for node in vol.nodes : [
      for i in range(vol.count) : {
        name   = "${volgroup}-${node}-${i}"
        node   = local.nodes[node]
        path   = "${vol.path_prefix}/${volgroup}-${i}"
        volume = vol
        group = volgroup
      }
    ]
  ]]) : b.name => b }
}

# output local_volumes {
#     value = local.volumes
# }

resource "null_resource" "volume_dir" {
  for_each = local.volumes

  provisioner "remote-exec" {
    inline = ["sudo mkdir -pv ${each.value.path}"]
  }
  connection {
    host        = each.value.node.public_ip
    user        = lookup(data.vault_generic_secret.cluster.data, "ssh_user", "ubuntu")
    private_key = data.vault_generic_secret.cluster.data.ssh_private_key
  }
}


resource "kubernetes_persistent_volume" "lv" {
  for_each = local.volumes
  metadata {
    name = each.key
    labels = {
      "local-volumes.core.stackd.cloud/group" = each.value.group
    }
  }
  spec {
    capacity = {
      storage = each.value.volume.size
    }
    storage_class_name               = each.value.volume.storageClassName
    persistent_volume_reclaim_policy = "Retain"
    access_modes                     = each.value.volume.accessModes
    persistent_volume_source {
      local {
        path = each.value.path
      }
    }
    node_affinity {
      required {

        dynamic "node_selector_term" {
          for_each = each.value.volume.nodeSelectorTerms
          content {

            dynamic "match_expressions" {
              for_each = node_selector_term.value.matchExpressions
              content {
                key      = match_expressions.value.key
                operator = match_expressions.value.operator
                values   = match_expressions.value.values
              }
            }
          }
        }
      }
    }

  }
}