#!/bin/bash
set -e

crontab /etc/cron.d/backup-schedule
cron

exec tail -f /dev/null
