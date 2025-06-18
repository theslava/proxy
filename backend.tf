terraform {
    backend "s3" {
        bucket = "home-tf-states"
        key    = "proxy"
        region = "us-west-2"
        profile = "terraform"
    }
}
