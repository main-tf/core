data "vault_generic_secret" "ah" {
  path = "kv/${var.env}/ah"
}

provider "ah" {
  access_token = data.vault_generic_secret.ah.data["access_token"]
}