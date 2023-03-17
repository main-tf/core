data "vault_generic_secret" "aws" {
  path = "kv/${var.env}/aws"
}

provider "aws" {
  region     = data.vault_generic_secret.aws.data["region"]
  access_key = data.vault_generic_secret.aws.data["access_key"]
  secret_key = data.vault_generic_secret.aws.data["secret_key"]

  default_tags {
    tags = {
      Environment       = var.env
      KubernetesCluster = var.env
    }
  }
}
