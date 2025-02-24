#------------------------------------------------------------------------------#
# pull the EKS K8S auth using data source created in the eks deployment phase  #
#------------------------------------------------------------------------------#
data "aws_eks_cluster" "eks" {
  name = var.config.eks.name
}

provider "aws" {
  default_tags {
    tags = var.config.default_tags
  }
  region = var.config.aws.region
}

# use the eks data to get the eks details
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", var.config.eks.name]
  }
}

# use the eks data to get the eks details
provider "helm" {
  debug = true
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", var.config.eks.name]
    }
  }
}