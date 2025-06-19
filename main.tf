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
  name        = "ssh_host"
  description = "Allow inbound SSH from home and HTTP from anywhere"
  vpc_id      = aws_default_vpc.default.id
}

resource "aws_vpc_security_group_egress_rule" "egress_all" {
  security_group_id = aws_security_group.ssh_host.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_home" {
  security_group_id = aws_security_group.ssh_host.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "${data.http.public_ip.response_body}/32"
  from_port         = "22"
  to_port           = "22"
}

resource "aws_vpc_security_group_ingress_rule" "http_from_home" {
  security_group_id = aws_security_group.ssh_host.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "${data.http.public_ip.response_body}/32"
  #cidr_ipv4   = "0.0.0.0/0"
  from_port = "80"
  to_port   = "80"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.ssh_host.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = "443"
  to_port           = "443"
}

resource "aws_vpc_security_group_ingress_rule" "group" {
  security_group_id            = aws_security_group.ssh_host.id
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.ssh_host.id
}

resource "aws_instance" "ssh" {
  ami                    = data.aws_ami.ssh.id
  instance_type          = "t4g.nano"
  key_name               = "aws"
  vpc_security_group_ids = [aws_security_group.ssh_host.id]
  user_data = <<EOF
  yum update
  yum install -y ansible
  EOF
}

resource "aws_lb" "proxy" {
  name            = "proxy-terraform-elb"
  internal        = "false"
  security_groups = [aws_security_group.ssh_host.id]
  subnets         = "${data.aws_subnets.default_vpc_subnets.ids}"

  access_logs {
    bucket = "home-tf-states"
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "theslava.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "ha.theslava.com",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "front_end" {
  name     = "proxy-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.proxy.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.proxy.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.front_end.arn
  target_id        = aws_instance.ssh.id
  port             = 80
}
