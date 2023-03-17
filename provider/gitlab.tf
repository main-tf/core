variable "gitlab_token" {
  type = string
}

provider "gitlab" {
  token    = var.gitlab_token
  base_url = "https://git.${var.project}.link/api/v4/"
}