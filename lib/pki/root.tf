variable "dns_zone" {
  type        = string
  default     = "unset"
  description = "dns zone"
}


locals {
  dns_zone = format("%s.%s", local.stackd.env, local.stackd.dns_zone)
}

resource "vault_mount" "root" {
  path                      = format("pki-%s-root", local.stackd.env)    #####
  type                      = "pki"
  default_lease_ttl_seconds = 315350000
  max_lease_ttl_seconds     = 315360000
}

resource "tls_private_key" "root_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "root_cert" {
  private_key_pem = tls_private_key.root_key.private_key_pem
  subject {
    common_name  = "${local.stackd.env} Root CA"
    organization = local.stackd.env
    //  organizational_unit = "master"
    //  street_address = ["33 Main Street"]
    //  locality = "Beverly Hills"
    //  province = "CA"
    //  country = "USA"
    //  postal_code = "90210"

  }
  # 175200 = 20 years
  validity_period_hours = 175200
  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
  is_ca_certificate = true

}

/*

resource "vault_pki_secret_backend_config_urls" "config_urls" {
  depends_on = [ vault_mount.root ]  
  backend              = vault_mount.root.path
  issuing_certificates = ["${var.vault_address}/v1/pki-${local.stackd.env}/ca"]
  crl_distribution_points= ["${var.vault_address}/v1/pki-${local.stackd.env}/crl"]
}

*/

// resource "vault_pki_secret_backend_role" "root" {
//   backend          = vault_mount.root.path
//   name             = "root"
//   ttl              = 315340000 // 10y
//   allow_ip_sans    = true
//   key_type         = "rsa"
//   key_bits         = 4096
//   allowed_domains  = [local.dns_zone]
//   allow_subdomains = true
// }

// resource "vault_pki_secret_backend_role" "ca" {
//   backend          = vault_mount.root.path
//   name             = "ca"
//   require_cn        = true
//   no_store          = true
//   ttl              = 315340000 // 10y
//   allow_ip_sans    = true
//   key_type         = "ec"
//   key_bits         = 224
//   allow_any_name = true
//   key_usage = ["KeyUsageDigitalSignature", "KeyUsageCertSign"]
// }
/*





resource "vault_pki_secret_backend_root_cert" "root" {
  depends_on            = [vault_mount.root]
  backend               = vault_mount.root.path
  type                  = "internal"
  common_name           = local.stackd.env
  ttl                   = "315360000"
  format                = "pem"
  private_key_format    = "der"
  key_type              = "rsa"
  key_bits              = 4096
  exclude_cn_from_sans  = true
  ou                    = local.stackd.env
//  organization          = "My organization"
}*/

resource "vault_generic_secret" "ca" {
  path = format("kv/%s/pki/ca", local.stackd.env)
  data_json = jsonencode({
    crt        = tls_self_signed_cert.root_cert.cert_pem
    key        = tls_private_key.root_key.private_key_pem
    pem_bundle = join("", [tls_private_key.root_key.private_key_pem, tls_self_signed_cert.root_cert.cert_pem])
  })
  //  lifecycle {
  //         prevent_destroy = true
  // }
}

data "vault_generic_secret" "ca" {
  depends_on = [vault_generic_secret.ca]
  path       = format("kv/%s/pki/ca", local.stackd.env)
}


resource "vault_pki_secret_backend_config_ca" "root" {
  depends_on = [vault_mount.root, tls_private_key.root_key, data.vault_generic_secret.ca]
  backend    = vault_mount.root.path
  pem_bundle = data.vault_generic_secret.ca.data["pem_bundle"]
}

// resource "vault_pki_secret_backend_sign" "cm" {
//   depends_on = [vault_pki_secret_backend_role.ca]
//   backend    = vault_mount.root.path
//   name       = vault_pki_secret_backend_role.ca.name
//   csr               = vault_pki_secret_backend_intermediate_cert_request.certmanager.csr
//   common_name          = local.stackd.env
// }

// resource "vault_pki_secret_backend_cert" "cm" {
//   depends_on = [vault_pki_secret_backend_role.ca]

//   backend = vault_mount.root.path
//   name = vault_pki_secret_backend_role.ca.name

//   common_name = local.stackd.env
// }


output "ca_cert" {
  // value = vault_pki_secret_backend_root_cert.root.certificate //
  value = tls_self_signed_cert.root_cert.cert_pem
}

output "cert" {
  // value = vault_pki_secret_backend_root_cert.root.certificate //
  value = tls_self_signed_cert.root_cert.cert_pem
}