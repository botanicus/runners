require 'ostruct'

OpenStruct.new(
  loggly_url: ENV.fetch('LOGGLY_URL'),
  dropbox_access_token: ENV.fetch('DROPBOX_ACCESS_TOKEN'),
  keep_days: ENV.fetch('KEEP_DAYS') { 45 }.to_i,
  parent_folder: ENV.fetch('PARENT_FOLDER') { 'Pictures' }
)
