output "connection_info" {
  description = "Connection info for the candidate"
  value       = <<-EOT
    ${aws_instance.challenge.public_ip}
    user: ${var.candidate_username}
    password: ${var.candidate_password}
  EOT
  sensitive   = true
}
