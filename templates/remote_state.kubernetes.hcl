
remote_state {
  backend = "kubernetes"
  config = {
    secret_suffix = "${service}"
    namespace = "kube-state"
    load_config_file = false 
   
    //   client_key = base64decode(dependency.cluster.outputs.k8s.client_key_data)
    //   client_certificate = base64decode(dependency.cluster.outputs.k8s.client_certificate_data)
    //   cluster_ca_certificate = base64decode(dependency.cluster.outputs.k8s.certificate_authority_data)
    // //  kubeconfig = module.kubernetes.kubeconfig
    //   host = dependency.cluster.outputs.k8s.endpoint
    host                   = dependency.cluster.outputs.cluster["client_endpoint"]
    cluster_ca_certificate = dependency.cluster.outputs.cluster["cluster_ca_certificate"]
    client_certificate     = dependency.cluster.outputs.cluster["client_certificate"]
    client_key             = dependency.cluster.outputs.cluster["client_key"]
  }
}

dependency "cluster" {
  config_path = "../sys-cluster-secret"
}