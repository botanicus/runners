require 'ostruct'

OpenStruct.new(
  # Standard keys.
  loggly_url: ENV.fetch('LOGGLY_URL'),

  # Extra keys.
  dropbox_access_token: ENV.fetch('DROPBOX_ACCESS_TOKEN'),
  days_to_keep: ENV.fetch('DAYS_TO_KEEP') { 45 }.to_i,
  parent_folder: ENV.fetch('PARENT_FOLDER') { 'Pictures' }
)
