variable "vault2vault" {
  type        = any
  default     = []
  description = "copy secret fro m vault to vault"
}

data "vault_generic_secret" "vault2vault" {
  count = length(var.vault2vault)
  path  = var.vault2vault[count.index].src
}

resource "vault_generic_secret" "vault2vault" {
  count     = length(var.vault2vault)
  path      = var.vault2vault[count.index].dest
  data_json = data.vault_generic_secret.vault2vault[count.index].data_json
}