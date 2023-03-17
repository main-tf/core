generate "provider.${provider}" {
  path = "provider.${provider}.tf"
  if_exists = "overwrite_terragrunt"
  contents = file("${root}/provider/${provider}.tf")
}
