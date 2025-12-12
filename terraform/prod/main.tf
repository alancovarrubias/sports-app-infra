module "infra" {
  source = "./modules/infra"
}

module "k8s" {
  source        = "./modules/k8s"
  db_uri        = module.infra.database_uri
  cache_uri     = module.infra.cache_uri
  registry_name = module.infra.registry_name
}
