resource "tls_private_key" "ssh" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "local_sensitive_file" "ssh_private_key" {
  filename        = "${path.module}/artifact/id_ecdsa"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  filename = "${path.module}/artifact/id_ecdsa.pub"
  content  = tls_private_key.ssh.public_key_openssh
}

data "vault_generic_secret" "cluster" {
  path = "kv/${local.stackd.env}/cluster"
}

resource "vault_generic_secret" "cluster" {
  path = "kv/${local.stackd.env}/cluster"
  data_json = jsonencode(merge(data.vault_generic_secret.cluster.data, {
    ssh_private_key = tls_private_key.ssh.private_key_pem
    ssh_public_key  = tls_private_key.ssh.public_key_openssh
  }))
}

output "ssh_public_key" {
  value = tls_private_key.ssh.public_key_openssh
}

output "ssh_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

output "ssh_private_key_file" {
  value = abspath(local_sensitive_file.ssh_private_key.filename)
}

output "ssh_public_key_file" {
  value = abspath(local_file.ssh_public_key.filename)
}