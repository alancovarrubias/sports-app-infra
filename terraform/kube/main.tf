terraform {
  required_version = ">= 0.12"
  backend "s3" {
    key    = "kube/state.tfstate"
    region = "us-west-1"
  }
}
