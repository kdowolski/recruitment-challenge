# Recruitment Challenge — Linux Troubleshooting

EC2 instance with Docker-based troubleshooting scenarios for recruitment.

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.5

## Usage

```bash
cd recruitment-challenge

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Set candidate_password and optionally allowed_ssh_cidr

terraform init
terraform apply
```

Terraform outputs the public IP and SSH command.
Wait ~3 minutes after `apply` for user-data to finish (Docker install + build).

## Candidate instructions

Send to the candidate:

> Connect to the server via SSH:
>
>     ssh candidate@<IP>
>     Password: <password>
>
> **Task:** The server is running a Docker container called `challenge-server`.
> Users report that it is consuming excessive CPU.
> Diagnose the issue, fix it, and make sure it does not come back.

## Expected solution

1. `docker exec -it challenge-server bash`
2. `top` or `htop` — find `backup-agent` eating 100% CPU
3. `kill <pid>` — but it comes back after ~1 minute
4. `crontab -l` — find the cron entry respawning it every minute
5. `crontab -r` or remove the entry, then kill remaining processes

## Teardown

```bash
terraform destroy
```

## Adding more challenges

Place new Dockerfiles in `docker/` or create additional containers
in `user-data.sh`. Each challenge should be an independent container.
