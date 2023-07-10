/*
deploys helm chart with vars defined in schema
*/

variable "chart_values" {

  default = {}

}

variable "chart_name" {

}

variable "chart_version" {

}

variable "chart_repository" {

}

variable chart_postrender {
    default = null
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = local.stackd.namespace
  }
}

resource "random_password" "admin" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "kubernetes_secret" "admin" {
  metadata {
    name      = "admin-password"
    namespace = local.stackd.namespace
  }
  data = {
    password = random_password.admin.result
  }
}

output "namespace" {
  value = local.stackd.namespace
}

output "service_name" {
  value = local.stackd.service
}

resource "helm_release" "app" {
  depends_on       = [kubernetes_namespace.ns, kubernetes_secret.admin]
  create_namespace = false
  name             = local.stackd.service
  repository       = var.chart_repository
  chart            = var.chart_name
  version          = var.chart_version
  namespace        = local.stackd.namespace

  dynamic postrender {
    for_each = var.chart_postrender != null ? [1] : []
    content {
      binary_path = var.chart_postrender.binary_path
      args        = var.chart_postrender.args
    }
  }
 
  values = [yamlencode(merge({
    clusterDomain = "${local.stackd.cluster}.local",
    auth = {
      existingSecret    = "admin-password"
      existingSecretKey = "password"
    }
    },
  var.chart_values))]

}
