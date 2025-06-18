output "ssh_public_ip" {
  value = aws_instance.ssh.public_ip
}

output "local_public_ip" {
  value = data.http.public_ip.response_body
}

