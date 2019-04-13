#!/usr/bin/env ruby

require 'instapaper'

username = ENV.fetch('INSTAPAPER_USERNAME')
password = ENV.fetch('INSTAPAPER_PASSWORD')

client = Instapaper::Client.new
client.access_token(username, password)

client = Instapaper::Client.new do |client|
  client.consumer_key = YOUR_CONSUMER_KEY
  client.consumer_secret = YOUR_CONSUMER_SECRET
  client.oauth_token = YOUR_OAUTH_TOKEN
  client.oauth_token_secret = YOUR_OAUTH_TOKEN_SECRET
end
