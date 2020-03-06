# About

[DockerHub](https://cloud.docker.com/u/jakubstastny/repository/docker/jakubstastny/dropbox-servers-backup)

Backs up local and remote files into Dropbox.

# Usage

```sh
#!/bin/bash

IMAGE=jakubstastny/dropbox-servers-backup

SERVERS='
  {
    "dev": {"machine": "root@134.209.47.239", "paths": ["/root/projects"]},
    "sys": {"paths": ["/self/var/spool/cron/crontabs/root", "/self/root/cron"]}
  }
'

# We use an array, because on a multiline command it's impossible to use comments.
# This requires bash to be used rather than just plain sh.
docker_run_args=(
  --rm

  # Standard keys.
  -e LOGGLY_URL=https://logs-01.loggly.com/inputs/04192b39-fed2-471e-a1bd-2455943d8129/tag/ruby/
  -e PUSHOVER_USER_KEY=$PUSHOVER_USER_KEY
  -e PUSHOVER_APP_TOKEN=$PUSHOVER_APP_TOKEN
  # Extra keys.
  -e DROPBOX_ACCESS_TOKEN=$DROPBOX_ACCESS_TOKEN
  # Servers.
  -e SERVERS=$SERVERS

  # Volumes.
  -v /root/backups:/backups
  -v /:/self
  -v /root/.ssh:/root/.ssh
)

# Extends args with whatever is passed into $@ of this script, such as -it.
docker_run_args=("${docker_run_args[@]}" "$@")
docker pull $IMAGE && docker run "${docker_run_args[@]}" $IMAGE
```

# Configuration

- `DROPBOX_ACCESS_TOKEN`
- `LOGGLY_URL` where the logs should be sent to.
