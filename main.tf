# 1. The VPC
module "vpc_eu_central" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=26c38a66f12e7c6c93b6a2ba127ad68981a48671"

  
  name            = "eu-prod-vpc"
  cidr            = "10.10.0.0/16"
  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# 2. The Transit Gateway (Hub)
resource "aws_ec2_transit_gateway" "frankfurt_hub" {
  description = "EU Central Transit Hub"
  tags = {
    Name = "Frankfurt-Hub"
  }
}
