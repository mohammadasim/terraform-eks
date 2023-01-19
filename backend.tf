terraform {
  backend "s3" {
    bucket  = "191998317647terraform-state-bucket"
    key     = "eks-deployment/terraform.tfstate"
    region  = "eu-west-1"
    profile = "default"
  }
}