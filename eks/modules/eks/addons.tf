#--------------------#
# Kubernetes Addons  #
#--------------------#

# eks main addons
# source:
module "main_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.20"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # We want to wait for the Fargate profiles to be deployed first
  create_delay_dependencies = [for prof in module.eks.fargate_profiles : prof.fargate_profile_arn]

  eks_addons = {
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
        # Ensure that the we fully utilize the minimum amount of resources that are supplied by
        # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
        # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
        # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
        # compute configuration that most closely matches the sum of vCPU and memory requests in
        # order to ensure pods always have the resources that they need to run.
        resources = {
          limits = {
            cpu = "0.25"
            # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
          requests = {
            cpu = "0.25"
            # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
        }
      })
    }
    vpc-cni    = {}
    kube-proxy = {}
  }

  # Enable Karpenter
  enable_karpenter = true

  karpenter = {
    chart_version       = "1.1.2"
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password
  }

  karpenter_node = {
    iam_role_use_name_prefix = false
    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
  }

  tags = var.config.eks.tags

  depends_on = [module.eks, module.vpc]

}

# Additonal Addons
# Needed for the Model Monitoirng 
# source:
module "additional_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.20"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Install Prometheus and Grafana
  enable_metrics_server        = true
  enable_kube_prometheus_stack = true

  # Disable Prometheus node exporter
  kube_prometheus_stack = {
    values = [
      jsonencode({
        nodeExporter = {
          enabled = false
        },
        alertmanager = {
          enabled = false
        }
      })
    ]
  }

  # Install the nvidia-device-plugin
  helm_releases = {
    nvidia-plugin = {
      repository       = "https://nvidia.github.io/k8s-device-plugin"
      chart            = "nvidia-device-plugin"
      chart_version    = "0.17.0"
      namespace        = "nvidia-device-plugin"
      create_namespace = true
    }

    # This Helm chart configures the KubeRay Operator, which can be used for advanced setups.
    # For instance, serving a model across multiple nodes.
    # For more details: https://github.com/eliran89c/self-hosted-llm-on-eks/multi-node-serving.md 
    # kuberay = {
    #   repository       = "https://ray-project.github.io/kuberay-helm/"
    #   chart            = "kuberay-operator"
    #   version          = "1.1.0"
    #   namespace        = "kuberay-operator"
    #   create_namespace = true
    # }
  }

  tags = var.config.eks.tags

  depends_on = [kubectl_manifest.karpenter, module.main_addons, module.eks, module.vpc]
}