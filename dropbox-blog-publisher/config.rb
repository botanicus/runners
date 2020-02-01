require 'ostruct'

OpenStruct.new(
  # Standard keys.
  loggly_url: ENV.fetch('LOGGLY_URL'),
  pushover_app_token: ENV.fetch('PUSHOVER_APP_TOKEN'),
  pushover_user_key: ENV.fetch('PUSHOVER_USER_KEY'),

  # Extra keys.
  dropbox_access_token: ENV.fetch('DROPBOX_ACCESS_TOKEN'),
  drop_folder: ENV.fetch('DROP_FOLDER') { '/Escrituras/Blog/Drop to publish' },
  archive_folder: ENV.fetch('ARCHIVE_FOLDER') { '/Escrituras/Blog/Entradas publicadas' },
  repo: ENV.fetch('REPO') { 'git@github.com:jakub-stastny/data.blog.git' },
  git_email: ENV.fetch('GIT_EMAIL'),
  git_name: ENV.fetch('GIT_NAME') { "Docker::jakubstastny/dropbox-blog-publisher" },
  private_ssh_key: ENV.fetch('PRIVATE_SSH_KEY')
)
