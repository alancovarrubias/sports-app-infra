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
  cluster_name = "sports-app-stage"
}
