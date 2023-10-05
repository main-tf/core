resource "vault_mount" "client" {
  path                      = format("pki-%s-client", local.stackd.env)
  type                      = "pki"
  default_lease_ttl_seconds = 315350000
  max_lease_ttl_seconds     = 315360000
}

resource "vault_pki_secret_backend_role" "client" {
  backend        = vault_mount.client.path
  name           = "client"
  ttl            = 31534000 // 1y +-
  allow_any_name = true
  key_type       = "ec"
  key_bits       = 256
  server_flag    = false
  client_flag    = true
  key_usage      = ["KeyUsageClientAuth"]
}


resource "vault_pki_secret_backend_intermediate_cert_request" "client" {

  backend      = vault_mount.client.path
  type         = "exported"
  common_name  = format("%s-client", local.stackd.env)
  organization = format("%s client CA", local.stackd.env)
  key_type     = "ec"
  key_bits     = 256
}

resource "vault_pki_secret_backend_root_sign_intermediate" "client" {
  backend        = vault_mount.root.path
  csr            = vault_pki_secret_backend_intermediate_cert_request.client.csr
  use_csr_values = true
  common_name    = format("%s-client", local.stackd.env)
}

resource "vault_pki_secret_backend_intermediate_set_signed" "client" {
  backend = vault_mount.client.path

  certificate = join("\n", [
    vault_pki_secret_backend_root_sign_intermediate.client.certificate,
    data.vault_generic_secret.ca.data["crt"]
    //vault_pki_secret_backend_config_ca.root.certificate
  ])
}

resource "vault_pki_secret_backend_cert" "client" {

  backend = vault_mount.client.path
  name    = vault_pki_secret_backend_role.client.name

  common_name = format("%s-client", local.stackd.env)
}

output "client_certificate" {
  value = vault_pki_secret_backend_cert.client.certificate
}

output "client_issuing_ca" {
  value = vault_pki_secret_backend_cert.client.issuing_ca
}

output "client_ca_chain" {
  value = vault_pki_secret_backend_cert.client.ca_chain
}

output "client_private_key" {
  value     = vault_pki_secret_backend_cert.client.private_key
  sensitive = true
}

output "client_serial_number" {
  value = vault_pki_secret_backend_cert.client.serial_number
}

resource "random_password" "p12" {
  length = 32
}
locals {
  p12_pass = random_password.p12.result
}
resource "pkcs12_from_pem" "client" {
  password        = local.p12_pass
  cert_pem        = vault_pki_secret_backend_cert.client.certificate
  private_key_pem = vault_pki_secret_backend_cert.client.private_key
  ca_pem          = vault_pki_secret_backend_cert.client.ca_chain
}

output "pki_vault_client_role" {
  value = vault_pki_secret_backend_role.client.name
}


output "pki_vault_client_mount_path" {
  value = format("pki-%s-client", local.stackd.env)
}



output "client_p12" {
  value = pkcs12_from_pem.client.result
}
output "client_p12_password" {
  value     = local.p12_pass
  sensitive = true
}

// resource "vault_pki_secret_backend_sign" "ingress" {
//   depends_on           = [tls_cert_request.ingress]
//   backend              = local.pki_path
//   csr                  = tls_cert_request.ingress.cert_request_pem
//   name = "ca" // role name
//   common_name          = var.ingress_host
// }

// resource "vault_pki_secret_backend_root_sign" "ingress" {
//   depends_on           = [vault_pki_secret_backend_intermediate_cert_request.ingress]
//   backend              = "pki-${local.stackd.env}"
//   csr                  = vault_pki_secret_backend_intermediate_cert_request.ingress.csr
//   common_name          = format("%s %s", local.stackd.env, var.service)
//   exclude_cn_from_sans = true
//   ou                   = var.service
//   organization         = local.stackd.env
//   use_csr_values = true
// }
