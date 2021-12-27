
provider "aws" {
  region  = "us-west-2" # XXX make this configurable
}

resource "random_pet" "name" {}

#resource "aws_s3_bucket" "bucket" {
#  bucket = "nextcloud-${random_pet.name.id}"
#  acl    = "private"
#}

# https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest
module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "nextcloud-${random_pet.name.id}"
  acl    = "private"

  versioning = {
    enabled = false
  }

}

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "nextcloud-vpc"
  cidr = "10.69.0.0/16"

  azs             = ["us-west-1a"]
#  private_subnets = ["10.69.101.0/24"]
  private_subnets = []
  public_subnets  = ["10.69.1.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

#  tags = {
#    Terraform = "true"
#    Environment = "dev"
#  }
}

resource "aws_instance" "nextcloud" {
  ami           = "ami-078278691222aee06"
  instance_type = "t4g.micro"
  subnet_id     = module.vpc.public_subnets.0

  tags = {
    Name = "nextcloud"
  }
}

#resource "aws_eip" "nextcloud" {
#  vpc      = true
#  instance = aws_instance.nextcloud.id
#}

