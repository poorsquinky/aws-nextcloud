
provider "aws" {
  region  = "us-west-2" # XXX make this configurable
}

resource "random_pet" "name" {}

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

  azs             = ["us-west-2a"]
#  private_subnets = ["10.69.101.0/24"]
  private_subnets = []
  public_subnets  = ["10.69.1.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
}

resource "tls_private_key" "n" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "n" {
  key_name   = "nextcloud"
  public_key = tls_private_key.n.public_key_openssh
}

resource "local_file" "aws_key" {
  content  = tls_private_key.n.private_key_pem
  filename = "privkey.pem"
}

resource "aws_instance" "nextcloud" {
  ami                  = "ami-078278691222aee06"
  instance_type        = "t4g.micro"
  subnet_id            = module.vpc.public_subnets.0
  key_name             = aws_key_pair.n.key_name
  iam_instance_profile = aws_iam_instance_profile.nextcloud.name

  #  associate_public_ip_address = false

  user_data = <<EOF
#!/bin/bash
sudo snap install amazon-ssm-agent --classic
EOF

  tags = {
    Name = "nextcloud"
  }
}

# get my public IP address.  For now, it's the only thing that should be able to access.
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

module "nextcloud_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "nextcloud"
  description = "Nextcloud SG"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = "${chomp(data.http.myip.body)}/32"
    },
  ]
}

resource "aws_eip" "nextcloud" {
  vpc      = true
  instance = aws_instance.nextcloud.id
}

resource "aws_iam_instance_profile" "nextcloud" {
  name = "nextcloud"
  role = aws_iam_role.nextcloud.name
  path = "/"
}

resource "aws_iam_role" "nextcloud" {
  name               = "nextcloud"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  path               = "/"
  description        = "SSM permissions for Nextcloud"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "nextcloud" {
  name        = "nextcloud"
  policy      = data.aws_iam_policy.nextcloud.policy
  path        = "/"
  description = "SSM permissions for Nextcloud"
}

resource "aws_iam_role_policy_attachment" "nextcloud" {
  role       = aws_iam_role.nextcloud.name
  policy_arn = aws_iam_policy.nextcloud.arn
}

locals {
  iam_name   = "nextcloud-session-manager"
}

data "aws_iam_policy" "nextcloud" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

output "instance_id" {
  value = aws_instance.nextcloud.id
}

