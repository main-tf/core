
variable "tls" {
  type    = bool
  default = false
}


variable "http_auth" {
  type    = bool
  default = false
}

variable "tls_auth" {
  type    = bool
  default = false
}

variable "service_name" {
  type = string
}

variable "service_namespace" {
  type = string
}


variable "port_name" {
  type    = string
  default = "http"
}

variable "issuer" {
  type    = string
  default = "letsencrypt-dns"
}


locals {
  tls = (var.tls || var.tls_auth)
  # ingress = local.tls ? kubernetes_ingress_v1.svc_tls : kubernetes_ingress_v1.svc
  tls_auth_issuer = var.tls_auth_issuer != null ? var.tls_auth_issuer : "ca-${local.stackd.cluster}"
}



resource "kubernetes_ingress_v1" "svc" {

  count = local.tls ? 0 : 1

  wait_for_load_balancer = true

  metadata {
    name      = format("%s-ingress", local.stackd.service)
    namespace = var.service_namespace
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = local.stackd.ingress_host
      http {
        path {
          path = "/"
          backend {
            service {
              name = var.service_name
              port {
                name = var.port_name
              }
            }
          }
        }

      }
    }
  }
}

variable "tls_auth_issuer" {
  type    = string
  default = null

}


resource "kubernetes_ingress_v1" "svc_tls" {

  count = local.tls ? 1 : 0

  wait_for_load_balancer = true

  metadata {
    name      = local.stackd.service
    namespace = local.stackd.service_namespace
    annotations = merge({
      "kubernetes.io/tls-acme"         = "true"
      "cert-manager.io/cluster-issuer" = var.tls_auth ? local.tls_auth_issuer : local.stackd.issuer
      }, var.tls_auth ? {
      "custom.nginx.org/client-tls-auth"                                  = "true"
      "nginx.ingress.kubernetes.io/auth-tls-pass-certificate-to-upstream" = "true"
      "nginx.ingress.kubernetes.io/auth-tls-secret"                       = "kube-ingress/client-ca"
      "nginx.ingress.kubernetes.io/auth-tls-verify-client"                = "on"
      "nginx.ingress.kubernetes.io/auth-tls-verify-depth"                 = "1"
    } : {})
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host = local.stackd.ingress_host
      http {
        path {
          path = "/"
          backend {
            service {
              name = var.service_name
              port {
                name = var.port_name
              }
            }
          }
        }

      }
    }

    tls {
      hosts       = ["${local.stackd.ingress_host}"]
      secret_name = "${local.stackd.ingress_host}-tls"
    }
  }
}

output "host" {
  value = local.stackd.ingress_host
}

output "tls" {
  value = var.tls
}

output "tls_auth" {
  value = var.tls_auth
}