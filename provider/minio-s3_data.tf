
data "vault_generic_secret" "minio" {
  path = "kv/data/s3/root"
}

provider "minio" {
  alias        = "s3_data"
  minio_server = var.s3_data_minio_server
  // minio_region = var.minio_region
  minio_access_key = data.vault_generic_secret.minio.data["accesskey"]
  minio_secret_key = data.vault_generic_secret.minio.data["secretkey"]
}
