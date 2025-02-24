#-------------#
# Karpenter   #
#-------------#

# Required for public ECR where Karpenter artifacts are hosted
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

# Allow Karpenter access to the EKS cluster
resource "aws_eks_access_entry" "karpenter_node_access_entry" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.main_addons.karpenter.node_iam_role_arn
  type          = "EC2_LINUX"

  tags = var.config.eks.tags

  depends_on = [module.eks, module.vpc, module.main_addons]
}

# Karpenter K8S manifest
resource "kubectl_manifest" "karpenter" {
  for_each = fileset("${path.module}/karpenter", "*.yaml")

  yaml_body = templatefile("${path.module}/karpenter/${each.key}", {
    cluster_name = module.eks.cluster_name
  })

  depends_on = [module.main_addons, module.eks, module.vpc]
}

# public.ecr.aws Helm charts available only in us-east-1 region
# Required for public ECR where Karpenter artifacts are hosted
# TBD: This causes terraform plan configuration drift on each run. We should get rid of it.
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.us-east-1
}

