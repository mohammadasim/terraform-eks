data "aws_availability_zones" "available" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "xpkit-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${data.aws_availability_zones.available.names[0]}", "${data.aws_availability_zones.available.names[1]}", "${data.aws_availability_zones.available.names[2]}"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true
  public_subnet_tags = {
    "kubernetes.io/cluster/eks-cluster" = "owned"
    "kubernetes.io/role/elb"            = "1"
  }
  tags = {
    Name = "ps-test-vpc"
  }
}
