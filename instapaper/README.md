# About

[DockerHub](https://cloud.docker.com/u/jakubstastny/repository/docker/jakubstastny/instapaper-article-archiver)

Archive old Instapaper articles.

# Usage

```sh
#!/bin/bash

IMAGE=jakubstastny/instapaper

# We use an array, because on a multiline command it's impossible to use comments.
# This requires bash to be used rather than just plain sh.
docker_run_args=(
  --rm

  # Standard keys.
  -e LOGGLY_URL=https://logs-01.loggly.com/inputs/04192b39-fed2-471e-a1bd-2455943d8129/tag/ruby/
  -e PUSHOVER_USER_KEY=uae6tz3vefrmeno7omp7xh1gj3jvs5
  -e PUSHOVER_APP_TOKEN=aduptj95g5vc4sr89fwsiyopim2vv4
  # Extra keys.
  -e INSTAPAPER_OAUTH_CONSUMER_ID=cc5974fec29f42ddb593040b31e3a0d2
  -e INSTAPAPER_OAUTH_CONSUMER_SECRET=e89181adea82483494bff7888d43550b
  -e INSTAPAPER_USERNAME=jakub.stastny.pt+service@gmail.com
  -e INSTAPAPER_PASSWORD=iXbfjaUjNvMeu2ZBTBkAyfsQ
  -e MAX_BOOKMARKS_AT_ONCE=3
)

# Extends args with whatever is passed into $@ of this script, such as -it.
docker_run_args=("${docker_run_args[@]}" "$@")
docker pull $IMAGE && docker run "${docker_run_args[@]}" $IMAGE
```

# Configuration

- `LOGGLY_URL` where the logs should be sent to.
- `INSTAPAPER_OAUTH_CONSUMER_ID` and `INSTAPAPER_OAUTH_CONSUMER_SECRET`. Your OAuth credentials. You need to get these [from Instapaper](https://www.instapaper.com/main/request_oauth_consumer_token).
- `INSTAPAPER_USERNAME` and `INSTAPAPER_PASSWORD`.
- `INSTAPAPER_DAYS_TO_KEEP` how many days to keep. Defaults to `90` days.
- `MAX_BOOKMARKS_AT_ONCE` how many bookmarks can be processed in one go.
- `PUSHOVER_USER_KEY` and `PUSHOVER_APP_TOKEN`. Your [PushOver.net](http://pushover.net) credentials. You need to create a new app to get a new `PUSHOVER_APP_TOKEN`.
