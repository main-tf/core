locals {
  cluster_exec = jsondecode(data.vault_generic_secret.cluster.data["exec"])
}

provider "kubernetes" {
  experiments { manifest_resource = true }
  host                   = data.vault_generic_secret.cluster.data["client_endpoint"]
  cluster_ca_certificate = data.vault_generic_secret.cluster.data["cluster_ca_certificate"]
  exec {
    api_version = local.cluster_exec["apiVersion"]
    args        = local.cluster_exec["args"]
    command     = local.cluster_exec.command
  }
}