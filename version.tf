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
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
        }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
        }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.2"
        }
    }
}

provider "aws" {
    region = "ap-northeast-2"

    default_tags {
        tags = local.default_tags
    }
}

##
## The data source should cause a call to api.ecr-public.us-east-1.amazonaws.com as "ECR-public actions are only supported in the us-east-1 region"
##

provider "aws" {
  region = "us-east-1"
  alias = "virginia"
}

