provider "aws" {
  region                   = var.REGION
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

terraform {
  backend "s3" {}
}