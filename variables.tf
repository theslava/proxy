variable "domain" {
  type    = string
  description = "Domain where proxy lives"
  default = "theslava.com"
}

variable "profile" {
  type = string
  description = "AWS profile for auth"
  default = "terraform"
}

variable "region" {
  type = string
  description = "Region where everything should be deployed"
  default = "us-west-2"
}

variable "services" {
  type    = list(string)
  description = "Services to proxy"
  default = ["homeassistant", "jellyfin"]
}
