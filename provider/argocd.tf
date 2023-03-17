data "vault_generic_secret" "argocd" {
  path = "kv/ops/argocd/terraform"
}


provider "argocd" {
  server_addr = data.vault_generic_secret.argocd.data.addr
  auth_token  = data.vault_generic_secret.argocd.data.token
  #username = data.vault_generic_secret.argocd.data.username
  #password = data.vault_generic_secret.argocd.data.password
}