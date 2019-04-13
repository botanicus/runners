#!/usr/bin/env ruby

require 'pry'
require 'instapaper'

client_key = ENV.fetch('INSTAPAPER_OAUTH_CONSUMER_ID')
client_secret = ENV.fetch('INSTAPAPER_OAUTH_CONSUMER_SECRET')
username = ENV.fetch('INSTAPAPER_USERNAME')
password = ENV.fetch('INSTAPAPER_PASSWORD')
days_to_keep = ENV.fetch('INSTAPAPER_DAYS_TO_KEEP') { '90' }.to_i

# Helpers.
def delete_bookmark(bookmark)
  if client.delete_bookmark(bookmark.bookmark_id)
    STDERR.puts "~ DELETE #{bookmark.title} – #{bookmarks.url}"
  end
end

def notify_about_deletion(bookmark)
  bookmark.title
  bookmark.url
end

# Auth.
client = Instapaper::Client.new do |client|
  client.consumer_key = client_key
  client.consumer_secret = client_secret

  token = client.access_token(username, password)
  client.oauth_token = token.oauth_token
  client.oauth_token_secret = token.oauth_token_secret
end

# Main.
bookmarks = client.bookmarks(limit: 500).bookmarks

if bookmarks.length > 499
  STDERR.puts "~ Warning: only first 500 bookmarks are being inspected."
end

old_bookmarks = bookmarks.filter do |bookmark|
  # Take the more recent timestamp (save time or last progress time)
  # and compare with the days_to_keep variable.
  timestamp = [bookmark.time, bookmark.progress_timestamp].sort.last
  timestamp < (Date.today - days_to_keep)
end

old_bookmarks.each do |bookmark|
  delete_bookmark(bookmark) if notify_about_deletion(bookmark)
end
