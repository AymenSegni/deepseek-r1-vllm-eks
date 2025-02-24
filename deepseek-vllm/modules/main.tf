# deploy depkseek r1 with vllm helm chart 
# helm chart module source: https://github.com/cloudposse/terraform-aws-helm-release
module "deepseek" {
  source  = "cloudposse/helm-release/aws"
  version = "v0.10.1"

  # helm release settings 
  # atomic               = true
  cleanup_on_fail      = true
  timeout              = 300
  wait                 = true
  name                 = "deepseek-r1-${var.config.model_size}"
  create_namespace     = true
  kubernetes_namespace = "deepseek-r1-${var.config.model_size}"

  # required: OIDC issuer URL for the EKS cluste
  eks_cluster_oidc_issuer_url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer


  # Specify the Helm chart details to deploy
  chart         = "${path.module}/helm/deepseek-r1"
  chart_version = "0.1.0"


  # DeepSeek R1 Deployment Settings

  values = [

    templatefile("${path.module}/helm/deepseek-r1/values.yaml",

      {

        modelSize     = var.config.model_size
        memoryLimit   = var.config.resources.limits_memory
        cpuLimit      = var.config.resources.limits_cpu
        gpuLimit      = var.config.resources.limits_gpu
        memoryRequest = var.config.resources.requests_memory
        cpuRequest    = var.config.resources.requests_cpu
        gpuRequest    = var.config.resources.requests_gpu
        volumeSize    = var.config.volumes.size

      }
    )
  ]

  tags = var.config.default_tags

  #   set = [

  #     {
  #       name  = "modelSize"
  #       value = var.config.model_size
  #       type  = "string"

  #     },

  #     # -------------------------
  #     # Resource Configuration
  #     # -------------------------
  #     # Set memory limits for the container
  #     {
  #       name  = "memoryLimit"
  #       value = var.config.resources.limits_memory
  #       type  = "string"
  #       # Maximum memory allocation allowed for the container.
  #     },
  #     # Set memory requests for the container
  #     {
  #       name  = "memoryRequest"
  #       value = var.config.resources.requests_memory
  #       type  = "string"
  #       # Minimum memory allocation guaranteed for the container.
  #     },
  #     # Set CPU limits for the container
  #     {
  #       name  = "cpuLimit"
  #       value = var.config.resources.limits_cpu
  #       type  = "string"
  #       # Maximum CPU allocation allowed for the container.
  #     },
  #     # Set CPU requests for the container
  #     {
  #       name  = "cpuRequest"
  #       value = var.config.resources.requests_cpu
  #       type  = "string"
  #       # Minimum CPU allocation guaranteed for the container.
  #     },
  #     # Set GPU limits (using nvidia.com/gpu) for the container
  #     {
  #       name  = "gpuLimit"
  #       value = var.config.resources.limits_gpu
  #       type  = "string"
  #       # Maximum number of GPUs allowed for the container.
  #     },
  #     # Set GPU requests for the container
  #     {
  #       name  = "gpuRequest"
  #       value = var.config.resources.requests_gpu
  #       type  = "string"
  #       # Minimum number of GPUs allocated to the container.
  #     },

  #     # -------------------------
  #     # Node Scheduling Settings
  #     # -------------------------

  #     {
  #       name  = "instanceType"
  #       value = var.config.node.instance_type
  #       type  = "string"
  #     },

  #     # -------------------------
  #     # Extra Volume Configuration
  #     # -------------------------

  #     {
  #       name  = "volumeSize"
  #       value = var.config.volumes.size
  #       type  = "string"
  #       # Maximum size allocated for the extra volume.
  #     }
  #   ]
}
