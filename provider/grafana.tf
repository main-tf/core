data "vault_generic_secret" "grafana" {
  path = "kv/${var.env}/grafana/api"
}

provider "grafana" {
  url  = data.vault_generic_secret.grafana.data.url
  auth = data.vault_generic_secret.grafana.data.key
}
