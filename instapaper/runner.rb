#!/usr/bin/env ruby

require 'instapaper'
require 'pushover'
require 'logglier'

CONFIG = instance_eval(File.read(File.expand_path('../config.rb', __FILE__)))
LOGGER = Logglier.new(CONFIG.loggly_url, threaded: true)

LOGGER.info("Running botanicus/instapaper-article-archiver")

# Helpers.
def delete_bookmark(client, bookmark)
  if client.delete_bookmark(bookmark.bookmark_id)
    LOGGER.info "~ DELETE #{bookmark.title} – #{bookmark.url}"
  end
end

def notify_about_deletion(bookmark)
  message = Pushover::Message.create(
    token: CONFIG.pushover_app_token,
    user: CONFIG.pushover_user_key,
    title: "Instapaper article expired",
    message: bookmark.title,
    url: bookmark.url
  )
  LOGGER.info("PushOver message: #{message.inspect}")

  response = message.push
  LOGGER.info("PushOver message delivery status: #{response.status == 1}")
  response.status == 1
end

# Auth.
client = Instapaper::Client.new do |client|
  client.consumer_key = CONFIG.instapaper_client_key
  client.consumer_secret = CONFIG.instapaper_client_secret

  token = client.access_token(CONFIG.instapaper_username, CONFIG.instapaper_password)
  client.oauth_token = token.oauth_token
  client.oauth_token_secret = token.oauth_token_secret
end

# Main.
bookmarks = client.bookmarks(limit: 500).bookmarks
LOGGER.info("#{bookmarks.length} found")

if bookmarks.length > 499
  LOGGER.info("~ Warning: only first 500 bookmarks are being inspected.")
end

old_bookmarks = bookmarks.filter do |bookmark|
  # Take the more recent timestamp (save time or last progress time)
  # and compare with the days_to_keep variable.
  timestamp = [bookmark.time, bookmark.progress_timestamp].sort.last
  timestamp < (Date.today - CONFIG.days_to_keep)
end

LOGGER.info("#{old_bookmarks.length} are older than #{CONFIG.days_to_keep} days")

old_bookmarks.each do |bookmark|
  delete_bookmark(client, bookmark) if notify_about_deletion(bookmark)
end
