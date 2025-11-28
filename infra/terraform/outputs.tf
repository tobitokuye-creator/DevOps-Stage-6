output "server_public_ip" {
  description = "Public IP address of the server"
  value       = aws_eip.app_eip.public_ip
}

output "server_public_dns" {
  description = "Public DNS of the server"
  value       = aws_instance.app_server.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to server"
  value       = "ssh -i ${path.module}/devops-key.pem ubuntu@${aws_eip.app_eip.public_ip}"
}

output "domain_name" {
  description = "Application domain"
  value       = var.domain_name
}

output "application_url" {
  description = "Application URL"
  value       = "https://${var.domain_name}"
}

output "private_key_pem" {
  description = "Private SSH key (sensitive)"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}