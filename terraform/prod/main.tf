module "registry" {
  source = "../modules/registry"
}

module "infra" {
  source = "../modules/infra"
}

module "ingress" {
  source = "../modules/ingress"
}

module "newrelic" {
  source       = "../modules/newrelic"
  license_key  = var.newrelic_license_key
  cluster_name = "sports-app-prod"
}

module "dns" {
  source      = "./modules/dns"
  domain_name = var.domain_name
  ingress_ip  = module.ingress.ingress_ip
}
