#!/usr/bin/env ruby

require 'dropbox_api'
require 'logglier'
require 'yaml'

CONFIG = instance_eval(File.read(File.expand_path('../config.rb', __FILE__)))
LOGGER = Logglier.new(CONFIG.loggly_url, threaded: true)
CLIENT = DropboxApi::Client.new(CONFIG.dropbox_access_token)

LOGGER.info("Running botanicus/dropbox-blog-publisher")

# Drop-folder handling.
drop_folder_items = CLIENT.list_folder(CONFIG.drop_folder)

if drop_folder_items.entries.empty?
  LOGGER.info("Nothing found in #{CONFIG.drop_folder}")
else
  main_post_file = drop_folder_items.entries.find { |file| file.name.match(/\.md$/) }
  slug = main_post_file.name.split('.').first

  # Add published date.
  CLIENT.download(main_post_file) do |content|
    lines = content.split("\n")
    published_content = if content.include?('---')
      header = YAML.load(content)
      header[:date] = Time.now
      [header.to_yaml, '---', lines[lines.index('---')..-1]].join("\n\n")
    else
      header = {date: Time.now}
      [header.to_yaml, '---', lines[lines.index('---')..-1]].join("\n\n")
    end

    CLIENT.upload(main_post_file.path_display, published_content)
  end

  timestamp = Time.now.strftime('%Y-%m-%d')
  published_post_path = File.join(CONFIG.archive_folder, "#{timestamp}-#{slug}")
  CLIENT.create_folder(published_post_path)
  drop_folder_items.entries.each do |file|
    LOGGER.info("Moving #{file.name} -> #{published_post_path}")
    CLIENT.move(file.path_display, File.join(published_post_path, file.name))
  end
end

published_files_request = CLIENT.list_folder(CONFIG.archive_folder)

if published_files_request.has_more?
  LOGGER.info("IMPLEMENT ME")
end

# Download every published post from Dropbox and expose it on REPO_PATH.
File.write(CONFIG.private_ssh_key, '/root/id_rsa')

REPO_PATH = '/repo'
POSTS_PATH = '/repo/posts'

unless Dir.exist?("#{REPO_PATH}/.git")
  system("git clone #{CONFIG.repo} #{REPO_PATH}/.git --bare")
  Dir.chdir(REPO_PATH)
  system("git checkout .")
end

published_files_request.entries.each do |post_folder|
  Dir.mkdir(File.join(POSTS_PATH, post_folder.name))
  CLIENT.list_folder(post_folder.path_display).entries.each do |file|
    CLIENT.download(file.path_display) do |content|
      File.write(File.join(POSTS_PATH, post_folder.name, file.name), content)
    end
  end
end

Dir.chdir(REPO_PATH) do
  system("git add #{POSTS_PATH}")
  system("git commit -a -m 'Updates'")
end
