variable "kube2kube" {
  type        = any
  default     = []
  description = "copy k8s secrets"
}



data "kubernetes_secret" "kube2kube" {
  count = length(var.kube2kube)
  metadata {
    name      = var.kube2kube[count.index].src.name
    namespace = var.kube2kube[count.index].src.namespace
  }
}

resource "kubernetes_secret" "kube2kube" {
  count = length(var.kube2kube)
  metadata {
    name      = var.kube2kube[count.index].dest.name
    namespace = var.kube2kube[count.index].dest.namespace
  }
  data = { for n, v in data.kubernetes_secret.kube2kube[count.index].data: n => v 
    if contains(lookup(var.kube2kube[count.index].src, "only", keys(data.kubernetes_secret.kube2kube[count.index].data)), n)
  }
}