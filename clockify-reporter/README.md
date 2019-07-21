# About

[DockerHub](https://cloud.docker.com/u/botanicus/repository/docker/botanicus/clockify-reporter)

Archive old Instapaper articles.

# Usage

```
docker run --rm -e VAR_1=VAL_1 -e VAR_2=VAL_2 (...) botanicus/clockify-reporter
```

Replace `VAR_x`/`VAL_x` with variables from the configuration section.

# Configuration

- `LOGGLY_URL` where the logs should be sent to.
- `PUSHOVER_USER_KEY` and `PUSHOVER_APP_TOKEN`. Your [PushOver.net](http://pushover.net) credentials. You need to create a new app to get a new `PUSHOVER_APP_TOKEN`.
- TODO
