data "vault_generic_secret" "confluence" {
  path = "kv/global/confluence"
}


provider "confluence" {
  site  = data.vault_generic_secret.confluence.data.site
  user  = data.vault_generic_secret.confluence.data.user
  token = data.vault_generic_secret.confluence.data.token
}