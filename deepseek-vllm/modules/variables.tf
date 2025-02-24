variable "config" {
  type = object({

    aws = object({
      region = string
    })

    eks = object({
      name = string
    })

    model_size = string

    resources = object({
      limits_cpu      = number
      requests_cpu    = number
      limits_memory   = string
      requests_memory = string
      limits_gpu      = number
      requests_gpu    = number

    })

    # node = object({
    #   instance_type = string
    # })

    volumes = object({
      size = string
    })

    default_tags = object({
      aws_account_id   = string
      aws_account_name = string
    })
  })
  default = {
    aws = {
      region = "us-west-1"
    }
    eks = {
      name = "ai-ml-llm"
    }

    model_size = "7b"

    resources = {
      limits_cpu      = 4
      requests_cpu    = 2
      limits_memory   = "16Gi"
      requests_memory = "8Gi"
      limits_gpu      = 1
      requests_gpu    = 1
    }
    # node = {
    #   instance_type = "gdn4.xlarge"
    # }

    volumes = {
      size = "4Gi"

    }

    default_tags = {
      aws_account_id   = ""
      aws_account_name = ""
      project          = ""
    }
  }
}
