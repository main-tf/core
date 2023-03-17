data "vault_generic_secret" "sentry" {
  path = "kv/global/sentry"
}

provider "sentry" {
  token = data.vault_generic_secret.sentry.data.token
}