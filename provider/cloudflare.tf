data "vault_generic_secret" "cloudflare" {
  path = "kv/${var.env}/cloudflare"
}

provider "cloudflare" {
  email   = data.vault_generic_secret.cloudflare.data["email"]
  api_key = data.vault_generic_secret.cloudflare.data["api_key"]
}