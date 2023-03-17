${remote_state}

${providerss}

generate "variables" {
  path = "variables.tf"
  if_exists = "overwrite"
  contents = file("./variables.tf")
}

generate "versions" {
  path = "versions.tf"
  if_exists = "overwrite"
  contents = file("./versions.tf")
}

terraform {
  
  source = "${abssource}"

  extra_arguments "auto_approve" {
    commands  = ["apply", "destroy"]
    arguments = ["-auto-approve"]
  }
  
 extra_arguments "init_upgrade" {
    commands  = ["init"]
    arguments = ["-upgrade"]
  }
extra_arguments "nowarn" {
    commands  = ["plan"]
    arguments = ["-compact-warnings"]
  }

  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()

    arguments = [
      "-var-file=vars.tfvars.json",
      "-compact-warnings"
    ]

    env_vars = {
      %{if contains([for i in inputs: i.name], "sys-pki")}
      SSL_CERT_FILE = "./ca.crt"
      %{endif}
    }
  }

}

dependencies {
  paths = ${jsonencode(deps)}
}


%{for dep in inputs}
  dependency "${dep.name}" {
    config_path = "${dep.path}"
  }
%{endfor}

%{if length(inputs)>0}
inputs = {
  %{for dep in inputs}
  ${replace(dep.name, "-", "_")} = dependency["${dep.name}"].outputs
  %{endfor}
}
%{endif}


%{if contains([for i in inputs: i.name], "sys-pki")}

generate "ca_cert" {
  path = "ca.crt"
  contents = dependency.sys-pki.outputs.ca_cert
  if_exists = "overwrite"
}

generate "client_cert" {
  path = "client.crt"
  contents = dependency.sys-pki.outputs.client_certificate
  if_exists = "overwrite"
}

generate "client_key" {
  path = "client.key"
  contents = dependency.sys-pki.outputs.client_private_key
  if_exists = "overwrite"
}

%{endif}