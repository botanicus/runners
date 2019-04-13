require 'ostruct'

OpenStruct.new(
  instapaper_client_key: ENV.fetch('INSTAPAPER_OAUTH_CONSUMER_ID'),
  instapaper_client_secret: ENV.fetch('INSTAPAPER_OAUTH_CONSUMER_SECRET'),
  instapaper_username: ENV.fetch('INSTAPAPER_USERNAME'),
  instapaper_password: ENV.fetch('INSTAPAPER_PASSWORD'),
  days_to_keep: ENV.fetch('INSTAPAPER_DAYS_TO_KEEP') { '90' }.to_i,
  pushover_app_token: ENV.fetch('PUSHOVER_APP_TOKEN'),
  pushover_user_key: ENV.fetch('PUSHOVER_USER_KEY')
)
