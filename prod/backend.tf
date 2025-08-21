terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    key            = "prod/terraform.state"
    bucket         = "kojofintech-terraform-backend"
    region         = "us-east-2"
    use_lockfile = true
    encrypt        = true
  }
}
