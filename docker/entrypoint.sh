#!/bin/bash
set -e

crontab /etc/cron.d/backup-schedule
cron

/usr/local/bin/backup-agent >> /var/log/backup-agent.log 2>&1 &

exec tail -f /dev/null
