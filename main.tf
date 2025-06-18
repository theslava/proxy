terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
  profile = "terraform"
}

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "ssh_host" {
  name = "ssh_host"
  description = "Allow inbound SSH from home and HTTP from anywhere"
  vpc_id = aws_default_vpc.default.id
}

resource "aws_vpc_security_group_egress_rule" "egress_all" {
  security_group_id = aws_security_group.ssh_host.id
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_home" {
  security_group_id = aws_security_group.ssh_host.id
  ip_protocol = "tcp"
  cidr_ipv4   = "${data.http.public_ip.response_body}/32"
  from_port = "22"
  to_port = "22"
}

resource "aws_vpc_security_group_ingress_rule" "http_from_home" {
  security_group_id = aws_security_group.ssh_host.id
  ip_protocol = "tcp"
  cidr_ipv4   = "${data.http.public_ip.response_body}/32"
  #cidr_ipv4   = "0.0.0.0/0"
  from_port = "80"
  to_port = "80"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.ssh_host.id
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
  from_port = "443"
  to_port = "443"
}

resource "aws_instance" "ssh" {
  ami           = data.aws_ami.ssh.id
  instance_type = "t4g.nano"
  key_name      = "aws"
  vpc_security_group_ids = [aws_security_group.ssh_host.id]
}

