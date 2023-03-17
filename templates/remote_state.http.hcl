
remote_state {
  backend = "http"
  config = {
    address = local.state_url
    lock_address="$${local.state_url}/lock"
    unlock_address="$${local.state_url}/lock"
    username=local.gitlab_user
    password=local.gitlab_access_token
    lock_method="POST"
    unlock_method="DELETE"
    retry_wait_min=5
  }
}