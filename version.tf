locals {
    default_tags = {
        Terraform = "true"
    }
}

# 필요한 provider가 있다면 적절히 추가하여 사용합니다.
terraform {
    required_version = "1.5.7"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "5.34.0"
        }
    }
}

provider "aws" {
    region = "ap-northeast-2"
    
    default_tags {
        tags = local.default_tags
    }
}


