## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_deepseek"></a> [deepseek](#module\_deepseek) | cloudposse/helm-release/aws | v0.10.1 |

## Resources

| Name | Type |
|------|------|
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | n/a | <pre>object({<br/><br/>    aws = object({<br/>      region = string<br/>    })<br/><br/>    eks = object({<br/>      name = string<br/>    })<br/><br/>    model_size = string<br/><br/>    resources = object({<br/>      limits_cpu      = number<br/>      requests_cpu    = number<br/>      limits_memory   = string<br/>      requests_memory = string<br/>      limits_gpu      = number<br/>      requests_gpu    = number<br/><br/>    })<br/><br/>    # node = object({<br/>    #   instance_type = string<br/>    # })<br/><br/>    volumes = object({<br/>      size = string<br/>    })<br/><br/>    default_tags = object({<br/>      aws_account_id   = string<br/>      aws_account_name = string<br/>    })<br/>  })</pre> | <pre>{<br/>  "aws": {<br/>    "region": "us-west-1"<br/>  },<br/>  "default_tags": {<br/>    "aws_account_id": "",<br/>    "aws_account_name": "",<br/>    "project": ""<br/>  },<br/>  "eks": {<br/>    "name": "ai-ml-llm"<br/>  },<br/>  "model_size": "7b",<br/>  "resources": {<br/>    "limits_cpu": 4,<br/>    "limits_gpu": 1,<br/>    "limits_memory": "16Gi",<br/>    "requests_cpu": 2,<br/>    "requests_gpu": 1,<br/>    "requests_memory": "8Gi"<br/>  },<br/>  "volumes": {<br/>    "size": "4Gi"<br/>  }<br/>}</pre> | no |

## Outputs

No outputs.
