data "vault_generic_secret" "hetznerdns" {
  path = "kv/${var.env}/hcloud"
}

provider "hetznerdns" {
  apitoken = data.vault_generic_secret.hetznerdns.data["hetznerdns_token"]
}