# About

[DockerHub](https://cloud.docker.com/u/jakubstastny/repository/docker/jakubstastny/dropbox-blog-publisher)

Pushes blog posts from Dropbox to GitHub.

# Usage

```sh
#!/bin/bash

IMAGE=jakubstastny/dropbox-blog-publisher

# We use an array, because on a multiline command it's impossible to use comments.
# This requires bash to be used rather than just plain sh.
docker_run_args=(
  --rm

  # Standard keys.
  -e LOGGLY_URL=https://logs-01.loggly.com/inputs/04192b39-fed2-471e-a1bd-2455943d8129/tag/ruby/
  -e PUSHOVER_USER_KEY=uae6tz3vefrmeno7omp7xh1gj3jvs5
  -e PUSHOVER_APP_TOKEN=a4v7h81hubowyvfo3yaok6ym5bu9nx
  # Extra keys.
  -e DROPBOX_ACCESS_TOKEN=vRVBzr-D8vwAAAAAAAE1GOqInvjhAoPqNGwyZx56Zdl1GDMmIy9CB9difKFVEfOC
  -e PRIVATE_SSH_KEY="$(cat < /root/dropbox-blog-publisher.key)"
  -e GIT_EMAIL=jakub.stastny.pt+git@gmail.com

  # Volumes.
  -v /root/data.blog:/repo
)

# Extends args with whatever is passed into $@ of this script, such as -it.
docker_run_args=("${docker_run_args[@]}" "$@")
docker pull $IMAGE && docker run "${docker_run_args[@]}" $IMAGE
```

# Configuration

- `DROPBOX_ACCESS_TOKEN`
- `LOGGLY_URL` where the logs should be sent to.
- `DROP_FOLDER` an empty folder. When you put content inside (`hello-world.md` and `my-pic.jpg` for instance), it will create and publish a new blog post off it.
- `ARCHIVE_FOLDER` archive of published blog posts.
