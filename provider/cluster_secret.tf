data "vault_generic_secret" "cluster" {
  path = "kv/${var.env}/cluster"
}
