
terraform {

  backend "${tf_backend}" {}

  required_providers {

    %{for prov in required_providers}
      %{if prov.source != null}
        ${prov.name} = {
          source = "${prov.source}"
          version = "${prov.version}"
        }
      %{endif}
    %{endfor}
    
  }

}