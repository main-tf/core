variable "vault2kube" {
  type        = any
  default     = []
  description = "copy secret fro m vault to kubernetes"
}

data "vault_generic_secret" "vault2kube" {
  count = length(var.vault2kube)
  path  = var.vault2kube[count.index].src
}

resource "kubernetes_secret" "vault2kube" {
  count = length(var.vault2kube)
  metadata {
    name      = var.vault2kube[count.index].dest.name
    namespace = var.vault2kube[count.index].dest.namespace
  }
  data = data.vault_generic_secret.vault2kube[count.index].data
}