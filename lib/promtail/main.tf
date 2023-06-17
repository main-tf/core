resource "kubernetes_namespace" "ns" {
  metadata {
    name = local.stackd.namespace
  }
}

variable "loki_address" {
  type    = string
  default = null
}

locals {
  loki_address = local.stackd.loki_address                // == null ? data.vault_generic_secret.loki.data.address : var.loki_address
  loki_domain  = split("/", local.stackd.loki_address)[2] // https://ccc/
}

resource "helm_release" "promtail" {
  depends_on = [
    kubernetes_namespace.ns,
    kubernetes_manifest.loki_cert,
  ]
  name       = local.stackd.service
  namespace  = local.stackd.namespace
  chart      = "promtail"
  version    = "6.9.0"
  repository = "https://grafana.github.io/helm-charts"


  values = [
    yamlencode({
      extraVolumes = [{
        name = "loki-tls"
        secret = {
          secretName = "loki-tls"
        }
      }]
      extraVolumeMounts = [{
        name      = "loki-tls"
        mountPath = "/loki-tls/"
        readOnly  = true
      }]
      config = {
        clients = [
          {
            url = local.loki_address
            tls_config = {
              server_name = local.loki_domain
              ca_file     = "/loki-tls/ca.crt"
              key_file    = "/loki-tls/tls.key"
              cert_file   = "/loki-tls/tls.crt"
              # insecure_skip_verify = true
            }
            external_labels = {
              env     = local.stackd.env
              cluster = local.stackd.env
            }
          }
        ]
      }
    })
  ]


}

/*
data "vault_generic_secret" "loki" {
  path = "kv/${var.env}/loki/htpasswd"
}
*/
resource "kubernetes_manifest" "loki_cert" {

  manifest = {
    apiVersion = "cert-manager.io/v1"
    "kind"     = "Certificate"
    "metadata" = {
      "name"    = "loki-cert"
      namespace = local.stackd.namespace
    }
    "spec" = {
      secretName = "loki-tls"
      #  duration = "31536000" # 365d
      #  renewBefore = "360h"
      usages     = ["client auth"]
      commonName = local.stackd.service
      issuerRef = {
        name = "ca-data"
        kind = "ClusterIssuer"
      }
    }
  }
}