variable "vault_address" {
  type = string
}

variable "vault_token" {
  type = string
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
  // timeout token
  
}

# data "vault_generic_secret" "vault_v2" {
#   path = "kv/global/vault/v2"
# }

# data "vault_generic_secret" "vault_v3" {
#   path = "kv/global/vault/v3"
# }

# provider "vault" {
#   alias   = "v2"
#   address = data.vault_generic_secret.vault_v2.data.url
#   token   = data.vault_generic_secret.vault_v2.data.token
# }

# provider "vault" {
#   alias   = "v3"
#   address = data.vault_generic_secret.vault_v3.data.url
#   token   = data.vault_generic_secret.vault_v3.data.token
# }