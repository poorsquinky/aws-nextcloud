
provider "aws" {
  region  = "us-west-2" # XXX make this configurable
}

resource "random_pet" "name" {}

resource "aws_s3_bucket" "bucket" {
  bucket = "nextcloud-${random_pet.name.id}"
  acl    = "private"
}


