# deployment config in yaml format 
locals {
  config = yamldecode(file("config_deepseek-r1-qwen-7b.yaml"))
}

# deploy DeepSeek-R1-Distill-Qwen-7B
module "deepseek_r1_7b" {
  source = "../modules"
  config = local.config
}