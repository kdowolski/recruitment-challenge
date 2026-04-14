terraform {
  required_version = ">= 1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "challenge" {
  name_prefix = "recruitment-challenge-"
  description = "Allow SSH access for recruitment challenge"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                         = "recruitment-challenge"
    StarfishRecruitmentChallenge = "True"
    CreationTime                 = timestamp()
  }

  lifecycle {
    ignore_changes = [tags["CreationTime"]]
  }
}

resource "aws_instance" "challenge" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.challenge.id]

  instance_initiated_shutdown_behavior = "terminate"

  user_data = templatefile("${path.module}/user-data.sh", {
    candidate_username = var.candidate_username
    candidate_password = var.candidate_password
    auto_shutdown_minutes = var.auto_shutdown_minutes
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name                         = "recruitment-challenge"
    StarfishRecruitmentChallenge = "True"
  }

  lifecycle {
    ignore_changes = [tags["CreationTime"]]
  }
}
