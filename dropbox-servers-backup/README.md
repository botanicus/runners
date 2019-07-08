# About

[DockerHub](https://cloud.docker.com/u/botanicus/repository/docker/botanicus/dropbox-blog-publisher)

Pushes blog posts from Dropbox to GitHub.

# Usage

```
docker run --rm -e VAR_1=VAL_1 -e VAR_2=VAL_2 (...) botanicus/dropbox-blog-publisher
```

Replace `VAR_x`/`VAL_x` with variables from the configuration section.

# Configuration

- `DROPBOX_ACCESS_TOKEN`
- `LOGGLY_URL` where the logs should be sent to.
- `DROP_FOLDER` an empty folder. When you put content inside (`hello-world.md` and `my-pic.jpg` for instance), it will create and publish a new blog post off it.
- `ARCHIVE_FOLDER` archive of published blog posts.
