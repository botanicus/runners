require 'ostruct'

OpenStruct.new(
  loggly_url: ENV.fetch('LOGGLY_URL'),
  dropbox_access_token: ENV.fetch('DROPBOX_ACCESS_TOKEN'),
  drop_folder: ENV.fetch('DROP_FOLDER') { '/Escrituras/Blog/Drop to publish' },
  archive_folder: ENV.fetch('ARCHIVE_FOLDER') { '/Escrituras/Blog/Entradas publicadas' },
  repo: ENV.fetch('REPO') { 'git@github.com:botanicus/data.blog.git' }
)
