module "registry" {
  source = "../modules/registry"
}

module "infra" {
  source = "../modules/infra"
}

module "ingress" {
  source = "../modules/ingress"
}
