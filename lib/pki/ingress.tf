resource "vault_mount" "ingress" {
  type                      = "pki"
  path                      = format("pki-%s-ingress", var.env)
  default_lease_ttl_seconds = 63072000 # 2 years
  max_lease_ttl_seconds     = 63072000 # 2 years
  description               = "${var.env} cluster CA"
}

/*
resource tls_private_key ingress {
   algorithm = "ECDSA"
   rsa_bits = 4096
}


resource "tls_cert_request" "ingress" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.ingress.private_key_pem
 
  subject {
    common_name = format("%s-%s", var.env, var.service)
    organization = format("%s Inc", var.env)
  }
}
*/

resource "vault_pki_secret_backend_intermediate_cert_request" "ingress" {
  depends_on   = [vault_mount.ingress]
  backend      = vault_mount.ingress.path
  type         = "exported"
  common_name  = format("%s", var.env)
  organization = format("%s Inc", var.env)
  key_type     = "ec"
  key_bits     = 256
}

resource "vault_pki_secret_backend_root_sign_intermediate" "ingress" {
  depends_on = [vault_pki_secret_backend_intermediate_cert_request.ingress,
  vault_pki_secret_backend_config_ca.root]
  backend = vault_mount.root.path
  csr     = vault_pki_secret_backend_intermediate_cert_request.ingress.csr
  // name = "ca" // role name
  common_name    = format("%s", var.env)
  use_csr_values = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "ingress" {
  backend = vault_mount.ingress.path

  certificate = join("\n", [
    vault_pki_secret_backend_root_sign_intermediate.ingress.certificate,
    data.vault_generic_secret.ca.data["crt"]
  ])
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
//   backend              = "pki-${var.env}"
//   csr                  = vault_pki_secret_backend_intermediate_cert_request.ingress.csr
//   common_name          = format("%s %s", var.env, var.service)
//   exclude_cn_from_sans = true
//   ou                   = var.service
//   organization         = var.env
//   use_csr_values = true
// }

resource "vault_generic_secret" "ingress" {
  depends_on = [vault_pki_secret_backend_intermediate_set_signed.ingress]
  path       = "kv/${var.env}/pki/ingress"
  data_json = jsonencode({
    crt = vault_pki_secret_backend_root_sign_intermediate.ingress.certificate
    bundle = join("\n", [
      vault_pki_secret_backend_root_sign_intermediate.ingress.certificate,
      data.vault_generic_secret.ca.data["crt"]
    ])
    key = "${vault_pki_secret_backend_intermediate_cert_request.ingress.private_key}"
    ca  = data.vault_generic_secret.ca.data["crt"]
  })
}

data "vault_generic_secret" "ingress" {
  depends_on = [vault_generic_secret.ingress]
  path       = "kv/${var.env}/pki/ingress"
}
