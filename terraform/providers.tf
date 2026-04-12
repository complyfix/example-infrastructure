terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }

  backend "s3" {
    bucket         = "acme-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = "acme-platform"
    }
  }
}

provider "kubernetes" {
  host                   = module.compute.eks_endpoint
  cluster_ca_certificate = base64decode(module.compute.eks_ca_cert)
  token                  = module.compute.eks_token
}

provider "helm" {
  kubernetes {
    host                   = module.compute.eks_endpoint
    cluster_ca_certificate = base64decode(module.compute.eks_ca_cert)
    token                  = module.compute.eks_token
  }
}
