variable "project" {
  description = "The name of the project"
  type        = string
}

resource "docker_container" "vault" {
  name  = format("%s-vault", var.project)
  image = "vault:1.10.0"
  env = toset([
    for k in keys(var.vault_storage.creds) : format("%s=%s", k, var.vault_storage.creds[k])
  ])

  ports {
    internal = "8200"
    external = "8200"
  }

  command = ["vault", "server", "-config", "/vault/config/local.hcl"]

  upload {
    file    = "/vault/config/local.hcl"
    content = <<EOC
        disable_mlock = true
     ui = true
      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      
      storage "s3" {  
          bucket     = "${var.vault_storage.bucket}"
          region    =   "${var.vault_storage.region}"
          kms_key_id    =   "${var.vault_storage.creds.VAULT_AWSKMS_SEAL_KEY_ID}"
        }

    seal "awskms" {
         region    =   "${var.vault_storage.region}"
         kms_key_id    =   "${var.vault_storage.creds.VAULT_AWSKMS_SEAL_KEY_ID}"
     }

        EOC
  }

}