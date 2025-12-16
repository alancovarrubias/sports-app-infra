module "infra" {
  source = "./modules/infra"
}

module "k8s" {
  source = "./modules/k8s"
}
