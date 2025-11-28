terraform {
  backend "s3" {
    bucket         = "tobito-terraform-state-devops"
    key            = "devops-stage-6/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
