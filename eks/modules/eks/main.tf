#--------------------#
# Deploy EKS Cluster #
#--------------------#

# EKS Module
# Source:https://github.com/terraform-aws-modules/terraform-aws-eks
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.33.1"

  cluster_name    = var.config.eks.name
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Fargate profiles use the cluster primary security group
  # Therefore these are not used and can be skipped
  # driven by https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/faq.md#i-received-an-error-expect-exactly-one-securitygroup-tagged-with-kubernetesioclustername-
  create_node_security_group = false # default is true
  #  attach_cluster_primary_security_group = true # default is false
  create_cluster_security_group = false

  # Give the Terraform identity admin access to the cluster
  # which will allow it to deploy resources into the cluster
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  # Fargate is used to run the minimum number of cluster pods. Only those that should start before Karpenter.
  fargate_profiles = {
    system = {
      selectors = [
        {
          namespace = "karpenter",
        },
        {
          namespace = "kube-system",
          labels = {
            "k8s-app" = "kube-dns"
          }
        }
      ]
    }
  }

  tags = merge(var.config.eks.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.config.eks.name
  })

}


#-----------------------#
# Supporting resources  #
#-----------------------#

data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# module VPC
# source: https://github.com/terraform-aws-modules/terraform-aws-vpc
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.config.eks.name
  cidr = var.config.eks.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.config.eks.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.config.eks.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = var.config.eks.name
  }

  tags = var.config.eks.tags

}
