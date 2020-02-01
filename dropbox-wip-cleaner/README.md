# About

[DockerHub](https://cloud.docker.com/u/jakubstastny/repository/docker/jakubstastny/dropbox-wip-cleaner)

Pushes blog posts from Dropbox to GitHub.

# Usage

```
docker run --rm -e VAR_1=VAL_1 -e VAR_2=VAL_2 (...) jakubstastny/dropbox-wip-cleaner
```

Replace `VAR_x`/`VAL_x` with variables from the configuration section.

# Configuration

- `DROPBOX_ACCESS_TOKEN`
- `LOGGLY_URL` where the logs should be sent to.
- TODO
