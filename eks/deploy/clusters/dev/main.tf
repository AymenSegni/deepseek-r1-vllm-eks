module "eks" {
  source = "../../../modules/eks"
  config = local.config
}