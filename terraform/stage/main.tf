terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "sports-app-buck"
    key    = "stage/state.tfstate"
    region = "us-west-1"
  }
}
