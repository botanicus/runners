require 'ostruct'

OpenStruct.new(
  # Standard keys.
  loggly_url: ENV.fetch('LOGGLY_URL'),
  pushover_user_key: ENV.fetch('PUSHOVER_USER_KEY'),
  # Every runner should have its own PushOver app unless it doesn't use PushOver itself,
  # but rather only as an error reporting mechanism (notify_about_error in shared/runner.rb).
  # See https://pushover.net/apps/build
  pushover_app_token: ENV.fetch('PUSHOVER_APP_TOKEN'),

  # Extra keys.
  dropbox_access_token: ENV.fetch('DROPBOX_ACCESS_TOKEN'),
  days_to_keep: ENV.fetch('DAYS_TO_KEEP') { 45 }.to_i,
  parent_folder: ENV.fetch('PARENT_FOLDER') { 'Pictures' }
)
