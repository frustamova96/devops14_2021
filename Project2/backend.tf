terraform {
  backend "s3" {
    bucket         = "devops14-feruza"
    region         = "us-east-2"
    profile        = "prod"
    key            = "terraform.tfstate"
    dynamodb_table = "devops14-lock-table"
  }
}

