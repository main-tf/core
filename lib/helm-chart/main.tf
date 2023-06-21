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

resource "helm_release" "app" {
  depends_on       = [kubernetes_namespace.ns, kubernetes_secret.admin]
  create_namespace = false
  name             = local.stackd.service
  repository       = var.chart_repository
  chart            = var.chart_name
  version          = var.chart_version
  namespace        = local.stackd.namespace
  values = [yamlencode(merge({
    clusterDomain = "${local.stackd.cluster}.local",
    auth = {
      existingSecret    = "admin-password"
      existingSecretKey = "password"
    }
    },
  var.chart_values))]

}
