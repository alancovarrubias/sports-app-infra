module "infra" {
  source = "./modules/infra"
}

module "ingress" {
  source = "./modules/ingress"
}

module "dns" {
  source      = "./modules/dns"
  domain_name = var.domain_name
  ingress_ip  = module.ingress.ingress_ip
}
