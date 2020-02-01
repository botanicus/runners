# About

[DockerHub](https://cloud.docker.com/u/jakubstastny/repository/docker/jakubstastny/dropbox-group-photos)

Move photos in Dropbox from `Camera Uploads` to directories named by `yyy-mm` in configured location.

# Usage

```
docker run --rm -e VAR_1=VAL_1 -e VAR_2=VAL_2 (...) jakubstastny/dropbox-group-photos
```

Replace `VAR_x`/`VAL_x` with variables from the configuration section.

# Configuration

- `DROPBOX_ACCESS_TOKEN`
- `LOGGLY_URL` where the logs should be sent to.
- `DAYS_TO_KEEP` how many days do you want the photos to be kept in `Camera Uploads` before archiving. Defaults to `45`.
- `PARENT_FOLDER` where do you want to archive the photos. Defaults to `Pictures`.
