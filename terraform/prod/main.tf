module "infra" {
  source = "./modules/infra"
}

module "k8s" {
  source         = "./modules/k8s"
  db_uri         = module.infra.database_uri
  cache_uri      = module.infra.cache_uri
  football_image = "registry.digitalocean.com/sports/football:latest"
}
