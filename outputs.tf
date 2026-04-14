output "connection_info" {
  description = "Connection info for the candidate"
  value       = "${aws_instance.challenge.public_ip} user: ${var.candidate_username} password: ${var.candidate_password}"
  sensitive   = true
}
