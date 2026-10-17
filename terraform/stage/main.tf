module "registry" {
  source = "../modules/registry"
}

module "infra" {
  source = "../modules/infra"
}

module "ingress" {
  source = "../modules/ingress"
}

module "datadog" {
  source       = "../modules/datadog"
  api_key      = var.datadog_api_key
  cluster_name = "sports-app-stage"
}
