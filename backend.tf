terraform {
  backend "s3" {
    bucket       = "sovereign-state-storage-266859253671"
    key          = "global/s3/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}
