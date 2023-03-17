
data "vault_generic_secret" "hcloud" {
  path = "kv/${var.env}/hcloud"
}


provider "hcloud" {
  token = data.vault_generic_secret.hcloud.data["hcloud_token"]
}

