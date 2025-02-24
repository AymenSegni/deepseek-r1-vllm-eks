variable "config" {
  type = object({
    aws = object({
      account_id = string
      region     = string
    })
    eks = object({
      name     = string
      vpc_cidr = optional(string, "10.0.0.0/16")
      tags     = optional(map(string), {})
    })

    default_tags = object({
      aws_account_id   = string
      aws_account_name = string
    })

  })
  description = "EKS cluster configuration"
}

locals {
  default_tags_part = {
    aws_region       = var.config.aws.region
    aws_account_id   = "YOURACCOUNTID"
    aws_account_name = "YOURACCOUNTNAME"
    project          = "DeepSeek R1"
  }

  default_tags = merge(var.config.default_tags, local.default_tags_part)
}