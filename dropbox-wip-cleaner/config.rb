require 'ostruct'

OpenStruct.new(
  loggly_url: ENV.fetch('LOGGLY_URL'),
  dropbox_access_token: ENV.fetch('DROPBOX_ACCESS_TOKEN'),
  wip_folder: ENV.fetch('DROP_FOLDER') { '/WIP' }
)
