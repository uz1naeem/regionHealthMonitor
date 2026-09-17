terraform {
  backend "s3" {
    bucket         = "rhm-tfstate-024805779838"
    key            = "env/staging/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "rhm-tf-lock"
    encrypt        = true
  }
}
