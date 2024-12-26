terraform {
  required_version = ">= 0.12"
  backend "s3" {
    key    = "dev/state.tfstate"
    region = "us-west-1"
  }
}
