/*

    s3 storage + unseal

*/

variable project {
  type        = string
}


resource "aws_kms_key" "vault" {
  description  = format("%s-vault", var.project)
  multi_region = true
}

resource "aws_s3_bucket" "vault" {
  bucket = format("%s-vault", var.project)
  // acl = "private" 
}

data "aws_iam_policy_document" "vault_s3" {

  statement {
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = [
      //format("arn:aws:s3:::%s-vault", var.project),
      //format("arn:aws:s3:::%s-vault/*", var.project),
      aws_s3_bucket.vault.arn,
      format("%s/*", aws_s3_bucket.vault.arn),
    ]
  }

}

data "aws_iam_policy_document" "vault_kms" {

  statement {
    effect = "Allow"
    actions = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey",
    "kms:GenerateDataKey"]
    resources = [
      aws_kms_key.vault.arn
    ]
  }

}

resource "aws_iam_user" "vault" {
  name = format("%s-vault", var.project)
}

resource "aws_iam_access_key" "vault" {
  user = aws_iam_user.vault.name
}

resource "aws_iam_user_policy" "vault_s3" {
  name   = "${var.project}-vault-s3"
  user   = aws_iam_user.vault.name
  policy = data.aws_iam_policy_document.vault_s3.json
}

resource "aws_iam_user_policy" "vault_kms" {
  name   = "${var.project}-vault-kms"
  user   = aws_iam_user.vault.name
  policy = data.aws_iam_policy_document.vault_kms.json
}

output "creds" {
  value = {
    AWS_SECRET_ACCESS_KEY    = aws_iam_access_key.vault.secret
    AWS_ACCESS_KEY_ID        = aws_iam_access_key.vault.id
    VAULT_AWSKMS_SEAL_KEY_ID = aws_kms_key.vault.key_id
  }
  sensitive = true
}

output "bucket" {
  value = aws_s3_bucket.vault.id
}

output "region" {
  value = aws_s3_bucket.vault.region
}