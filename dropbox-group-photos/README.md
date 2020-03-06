# About

[DockerHub](https://cloud.docker.com/u/jakubstastny/repository/docker/jakubstastny/dropbox-group-photos)

Move photos in Dropbox from `Camera Uploads` to directories named by `yyy-mm` in configured location.

# Usage

```sh
#!/bin/bash

IMAGE=jakubstastny/dropbox-group-photos

# We use an array, because on a multiline command it's impossible to use comments.
# This requires bash to be used rather than just plain sh.
docker_run_args=(
  --rm

  # Standard keys.
  -e LOGGLY_URL=https://logs-01.loggly.com/inputs/04192b39-fed2-471e-a1bd-2455943d8129/tag/ruby/
  -e PUSHOVER_USER_KEY=uae6tz3vefrmeno7omp7xh1gj3jvs5
  -e PUSHOVER_APP_TOKEN=athfrmpm2i4khri69got5sqydfh3kzathfrmpm2i4khri69got5sqydfh3kz
  # Extra keys.
  -e DROPBOX_ACCESS_TOKEN=vRVBzr-D8vwAAAAAAAE1GOqInvjhAoPqNGwyZx56Zdl1GDMmIy9CB9difKFVEfOC
  -e PARENT_FOLDER=Fotos
)

# Extends args with whatever is passed into $@ of this script, such as -it.
docker_run_args=("${docker_run_args[@]}" "$@")
docker pull $IMAGE && docker run "${docker_run_args[@]}" $IMAGE
```

# Configuration

- `DROPBOX_ACCESS_TOKEN`
- `LOGGLY_URL` where the logs should be sent to.
- `DAYS_TO_KEEP` how many days do you want the photos to be kept in `Camera Uploads` before archiving. Defaults to `45`.
- `PARENT_FOLDER` where do you want to archive the photos. Defaults to `Pictures`.
