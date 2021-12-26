
resource "random_pet" "name" {}

resource "aws_s3_bucket" "bucket" {
  bucket = "nextcloud-${random_pet.name.id}"
  acl    = "private"

//  tags = {
//    Name        = "My bucket"
//    Environment = "Dev"
//  }
}


