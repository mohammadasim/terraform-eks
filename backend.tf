terraform {
  backend "s3" {
    bucket  = "<account-number>terraform-state-bucket"
    key     = "eks-deployment/terraform.tfstate"
    region  = "eu-west-1"
    profile = "default"
  }
}