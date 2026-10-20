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
  cluster_name                 = "sports-app-prod"
  database_metrics_endpoint    = module.infra.database_metrics_endpoint
  cache_metrics_endpoint       = module.infra.cache_metrics_endpoint
  metrics_credentials_username = module.infra.metrics_credentials_username
  metrics_credentials_password = module.infra.metrics_credentials_password
}

module "dns" {
  source      = "./modules/dns"
  domain_name = var.domain_name
  ingress_ip  = module.ingress.ingress_ip
}
