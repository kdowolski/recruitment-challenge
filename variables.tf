variable "aws_region" {
  description = "AWS region to deploy into"
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "candidate_username" {
  description = "SSH username for the candidate"
  default     = "candidate"
}

variable "candidate_password" {
  description = "SSH password for the candidate"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (restrict to candidate IP)"
  default     = "0.0.0.0/0"
}


variable "auto_shutdown_minutes" {
  description = "Auto-terminate instance after this many minutes (0 to disable)"
  default     = 240
}
