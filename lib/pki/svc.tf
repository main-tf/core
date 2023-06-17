resource "vault_mount" "svc" {
  type                      = "pki"
  path                      = format("pki-%s-svc", var.env)
  default_lease_ttl_seconds = 63072000 # 2 years
  max_lease_ttl_seconds     = 63072000 # 2 years
  description               = "${var.env} cluster CA"
}

resource "vault_pki_secret_backend_intermediate_cert_request" "svc" {
  depends_on   = [vault_mount.svc]
  backend      = vault_mount.svc.path
  type         = "exported"
  common_name  = format("%s-svc", var.env)
  organization = format("%s services CA", var.env)
  key_type     = "ec"
  key_bits     = 256
}

resource "vault_pki_secret_backend_root_sign_intermediate" "svc" {
  depends_on = [vault_pki_secret_backend_intermediate_cert_request.svc,
  vault_pki_secret_backend_config_ca.root]
  backend = vault_mount.root.path
  csr     = vault_pki_secret_backend_intermediate_cert_request.svc.csr
  // name = "ca" // role name
  common_name    = format("%s-svc", var.env)
  use_csr_values = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "svc" {
  backend = vault_mount.svc.path

  certificate = join("\n", [
    vault_pki_secret_backend_root_sign_intermediate.svc.certificate,
    data.vault_generic_secret.ca.data["crt"]
  ])
}

// resource "vault_pki_secret_backend_sign" "svc" {
//   depends_on           = [tls_cert_request.svc]
//   backend              = local.pki_path
//   csr                  = tls_cert_request.svc.cert_request_pem
//   name = "ca" // role name
//   common_name          = var.svc_host
// }

// resource "vault_pki_secret_backend_root_sign" "svc" {
//   depends_on           = [vault_pki_secret_backend_intermediate_cert_request.svc]
//   backend              = "pki-${var.env}"
//   csr                  = vault_pki_secret_backend_intermediate_cert_request.svc.csr
//   common_name          = format("%s %s", var.env, var.service)
//   exclude_cn_from_sans = true
//   ou                   = var.service
//   organization         = var.env
//   use_csr_values = true
// }

resource "vault_generic_secret" "svc" {
  depends_on = [vault_pki_secret_backend_intermediate_set_signed.svc]
  path       = "kv/${var.env}/pki/svc"
  data_json = jsonencode({
    crt = vault_pki_secret_backend_root_sign_intermediate.svc.certificate
    bundle = join("\n", [
      vault_pki_secret_backend_root_sign_intermediate.svc.certificate,
      data.vault_generic_secret.ca.data["crt"]
    ])
    key = "${vault_pki_secret_backend_intermediate_cert_request.svc.private_key}"
    ca  = data.vault_generic_secret.ca.data["crt"]
  })
}

data "vault_generic_secret" "svc" {
  depends_on = [vault_generic_secret.svc]
  path       = "kv/${var.env}/pki/svc"
}
