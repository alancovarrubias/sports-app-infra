module "infra" {
  source = "./modules/infra"
}

module "ingress" {
  source = "./modules/ingress"
}

module "dns" {
  source      = "./modules/dns"
  domain_name = "alancovarrubias.com"
  ingress_ip  = module.ingress.ingress_ip
}
