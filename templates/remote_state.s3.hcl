/*
$ export AWS_ACCESS_KEY_ID="anaccesskey"
$ export AWS_SECRET_ACCESS_KEY="asecretkey"
*/
remote_state {
  backend = "s3"
  config = {
    bucket = "${vars.tf_state_bucket}"
    key = "${vars.tf_state_key}"
    region = "eu-central-1"
    encrypt = true
  }
}