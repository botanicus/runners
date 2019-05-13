# About

[DockerHub](https://cloud.docker.com/u/botanicus/repository/docker/botanicus/instapaper-article-archiver)

Archive old Instapaper articles.

# Usage

```
docker run --rm -e VAR_1=VAL_1 -e VAR_2=VAL_2 (...) botanicus/instapaper-article-expirer
```

Replace `VAR_x`/`VAL_x` with variables from the configuration section.

# Configuration

- `LOGGLY_URL` where the logs should be sent to.
- `INSTAPAPER_OAUTH_CONSUMER_ID` and `INSTAPAPER_OAUTH_CONSUMER_SECRET`. Your OAuth credentials. You need to get these [from Instapaper](https://www.instapaper.com/main/request_oauth_consumer_token).
- `INSTAPAPER_USERNAME` and `INSTAPAPER_PASSWORD`.
- `INSTAPAPER_DAYS_TO_KEEP` how many days to keep. Defaults to `90` days.
- `MAX_BOOKMARKS_AT_ONCE` how many bookmarks can be processed in one go.
- `PUSHOVER_USER_KEY` and `PUSHOVER_APP_TOKEN`. Your [PushOver.net](http://pushover.net) credentials. You need to create a new app to get a new `PUSHOVER_APP_TOKEN`.
