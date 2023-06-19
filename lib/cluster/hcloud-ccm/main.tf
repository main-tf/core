resource "kubernetes_secret" "hcloud" {
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }

  data = {
    hcloudApiToken = data.vault_generic_secret.hcloud.data.hcloud_token
    network = data.hcloud_network.net.id
  }
}

data "hcloud_network" "net" {
  name = "${local.stackd.cluster}-network"
}

variable "versions" {
  type = map(string)
  default = {
    ccm = "v1.15.0"
    csi = "2.2.1"
  }
}


# resource "helm_release" "ccm" {
#   // legacy ccm. not use it anymore
#   chart            = "hcloud-cloud-controller-manager"
#   repository       = "https://helm-charts.mlohr.com/"
#   name             = "cloud-controller"
#   namespace        = "kube-system"
#   wait_for_jobs    = true
#   create_namespace = false
#   version          = "3.3.0"
#   set {
#     name  = "secret.existingSecretName"
#     value = "hcloud-token"
#   }

#   // set {
#   //   name = "config.addressFamily"
#   //   value = "dualstack"
#   // }

#   set {
#     name  = "config.privateNetworks.enabled"
#     value = "true"
#   }
#   set {
#     name  = "config.privateNetworks.id"
#     value = data.hcloud_network.net.id
#   }
#   set {
#     name  = "config.privateNetworks.subnet"
#     value = data.hcloud_network.net.ip_range
#   }


# }

resource "helm_release" "ccm" {
  chart            = "hcloud-cloud-controller-manager"                      
  repository       = "https://charts.hetzner.cloud"
  name             = "hccm"
  namespace        = "kube-system"
  wait_for_jobs    = true
  create_namespace = false
  version          = var.versions.ccm
 

  values = [
    yamlencode({
      args = {
        "configure-cloud-routes" = "false"
      }
      networking = {
        enabled = true
        clusterCIDR = data.hcloud_network.net.ip_range
      }
      env = {
        HCLOUD_TOKEN = {
          valueFrom = {
            secretKeyRef = {
              name = "hcloud"
              key = "hcloudApiToken"
            }
          }
        }
      }
    })
  ]

}

resource "helm_release" "csi" {
  chart            = "hcloud-csi-driver"
  repository       = "https://helm-charts.mlohr.com/"
  name             = "csi-driver"
  namespace        = "kube-system"
  wait_for_jobs    = true
  create_namespace = false
  version          = var.versions.csi

  set {
    name  = "secret.existingSecretName"
    value = "hcloud"
  }

  set {
    name  = "storageClass.isDefault"
    value = "true"
  }
  set {
    name  = "metrics.enabled"
    value = true
  }

}