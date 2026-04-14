output "instance_public_ip" {
  description = "Public IP of the challenge instance"
  value       = aws_instance.challenge.public_ip
}

output "ssh_command" {
  description = "SSH command for the candidate"
  value       = "ssh ${var.candidate_username}@${aws_instance.challenge.public_ip}"
}
