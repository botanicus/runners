require 'ostruct'

OpenStruct.new(
  dropbox_access_token: ENV.fetch('DROPBOX_ACCESS_TOKEN'),
  keep_days: ENV.fetch('KEEP_DAYS') { 45 }.to_i,
  parent_folder: ENV.fetch('PARENT_FOLDER') { 'Pictures' }
)
