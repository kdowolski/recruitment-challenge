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

COPY backup-agent /usr/local/bin/backup-agent
RUN chmod +x /usr/local/bin/backup-agent

COPY backup-schedule /etc/cron.d/backup-schedule
RUN chmod 0644 /etc/cron.d/backup-schedule

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
