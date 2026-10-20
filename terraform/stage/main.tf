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
  source                       = "../modules/datadog"
  api_key                      = var.datadog_api_key
  cluster_name                 = "sports-app-stage"
  database_metrics_endpoint    = module.infra.database_metrics_endpoint
  cache_metrics_endpoint       = module.infra.cache_metrics_endpoint
  metrics_credentials_username = module.infra.metrics_credentials_username
  metrics_credentials_password = module.infra.metrics_credentials_password
}
