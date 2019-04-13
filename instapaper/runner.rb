#!/usr/bin/env ruby

require 'instapaper'

client_key = ENV.fetch('INSTAPAPER_OAUTH_CONSUMER_ID')
client_secret = ENV.fetch('INSTAPAPER_OAUTH_CONSUMER_SECRET')
username = ENV.fetch('INSTAPAPER_USERNAME')
password = ENV.fetch('INSTAPAPER_PASSWORD')

client = Instapaper::Client.new do |client|
  client.consumer_key = client_key
  client.consumer_secret = client_secret

  token = client.access_token(username, password)
  client.oauth_token = token.oauth_token
  client.oauth_token_secret = token.oauth_token_secret
end

puts
p client.bookmarks
