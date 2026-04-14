#!/bin/bash
set -euxo pipefail

exec >/var/log/user-data.log 2>&1

# --- Enable SSH password authentication ---
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?KbdInteractiveAuthentication .*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
# Cloud image drop-in overrides main config — fix it
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf 2>/dev/null || true

# Ubuntu 24.04 uses ssh.service, not sshd.service
systemctl restart ssh

# --- Install Docker ---
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$${VERSION_CODENAME}") stable" |
    tee /etc/apt/sources.list.d/docker.list >/dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

systemctl enable docker
systemctl start docker

# --- Create candidate user (after Docker so the group exists) ---
useradd -m -s /bin/bash "${candidate_username}"
echo "${candidate_username}:${candidate_password}" | chpasswd
usermod -aG docker "${candidate_username}"
usermod -aG docker ubuntu

# --- Build and run the challenge container ---
mkdir -p /opt/challenge/docker
mkdir -p /opt/challenge/docker/backups
for i in $(seq 1 5); do
    dd if=/dev/urandom of="/opt/challenge/docker/backups/data_$${i}.bak" bs=1K count=64 2>/dev/null
done
cd /opt/challenge/docker/backups
sha256sum *.bak >/opt/challenge/docker/checksums.sha256
cd /opt/challenge/docker

cat >/opt/challenge/docker/backup-agent <<'SCRIPT'
#!/usr/bin/env python3
"""Backup agent — verifies integrity of backup files."""

import datetime
import hashlib
import os
import sys

BACKUP_DIR = "/var/backups/data"
CHECKSUM_FILE = "/var/backups/checksums.sha256"


def log(msg: str) -> None:
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] {msg}", flush=True)


def compute_checksum(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()


def load_checksums(path: str) -> dict:
    result = {}
    with open(path) as f:
        for line in f:
            checksum, name = line.strip().split("  ", 1)
            result[name] = checksum
    return result


def main() -> None:
    log(f"Starting backup integrity check (pid={os.getpid()})")
    expected = load_checksums(CHECKSUM_FILE)
    files = sorted(os.listdir(BACKUP_DIR))
    log(f"Loaded {len(expected)} checksums, found {len(files)} files to verify")
    idx = 0

    while idx < len(files):
        name = files[idx]
        path = os.path.join(BACKUP_DIR, name)
        actual = compute_checksum(path)

        if name in expected and expected[name] != actual:
            log(f"CORRUPTION DETECTED: {name}")
            print(f"CORRUPTION DETECTED: {name}", file=sys.stderr)


if __name__ == "__main__":
    main()
SCRIPT

cat >/opt/challenge/docker/backup-schedule <<'CRON'
*/3 * * * * /usr/local/bin/backup-agent >> /var/log/backup-agent.log 2>&1
CRON

cat >/opt/challenge/docker/entrypoint.sh <<'ENTRY'
#!/bin/bash
set -e

crontab /etc/cron.d/backup-schedule
cron

exec tail -f /dev/null
ENTRY

cat >/opt/challenge/docker/Dockerfile <<'DOCKER'
FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cron \
        python3 \
        procps \
        htop \
        vim \
        less \
    && rm -rf /var/lib/apt/lists/*

COPY backups/*.bak /var/backups/data/
COPY checksums.sha256 /var/backups/checksums.sha256

COPY backup-agent /usr/local/bin/backup-agent
RUN chmod +x /usr/local/bin/backup-agent

COPY backup-schedule /etc/cron.d/backup-schedule
RUN chmod 0644 /etc/cron.d/backup-schedule

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
DOCKER

cd /opt/challenge/docker
docker build -t backup-agent-server .
docker run -d --name backup-agent-server --cpuset-cpus="0" --memory=256m --memory-swap=256m backup-agent-server

# --- Auto-terminate after configured time ---
if [[ "${auto_shutdown_minutes}" -gt 0 ]]; then
    shutdown -P +${auto_shutdown_minutes}
fi

echo "=== Challenge setup complete ==="
