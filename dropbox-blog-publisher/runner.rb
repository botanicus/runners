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
  p [:m, main_post_file]
  p [:s, slug]

  # Add published date.
  CLIENT.download(main_post_file.path_display) do |content|
    lines = content.split("\n")
    published_content = if content.include?('---')
      header = YAML.load(content)
      header['date'] = Time.now
      [header.to_yaml.chomp.split("\n")[1..-1].join("\n"), '---', lines[lines.index('---')..-1].join("\n")].join("\n\n")
    else
      header = {'date' => Time.now}
      [header.to_yaml.chomp.split("\n")[1..-1].join("\n"), '---', lines.join("\n")].join("\n\n")
    end

    path = main_post_file.path_display
    new_path = File.expand_path("#{main_post_file.path_display}/../post.md")
    # path = "/Escrituras/Blog/Drop to publish/post.md"
    p [:p, path]
    p [:np, new_path]
    p [:c, published_content]
    CLIENT.upload(new_path, "#{published_content.chomp}\n")
    CLIENT.delete(path)
  end

  drop_folder_items = CLIENT.list_folder(CONFIG.drop_folder)
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
Dir.mkdir('/root/.ssh')
File.write('/root/.ssh/id_rsa', CONFIG.private_ssh_key)

REPO_PATH = '/repo'
POSTS_PATH = '/repo/posts'

def run(command)
  puts "$ #{command}"
  result = %x{#{command}}
  puts result unless result.empty?
  if $?.exitstatus != 0
    abort "\nExited with #{$?.exitstatus}"
  end
end

unless Dir.exist?("#{REPO_PATH}/.git")
  run "chmod 700 /root/.ssh"
  run "chmod 600 /root/.ssh/id_rsa"
  run "cat /root/.ssh/id_rsa"
  run "ssh-keyscan -H github.com >> ~/.ssh/known_hosts"
  run "git clone #{CONFIG.repo} repo"
  run "mv repo/.git #{REPO_PATH}/.git"
  Dir.chdir(REPO_PATH)
  run "git checkout ."
end

published_files_request.entries.each do |post_folder|
  post_folder_path = File.join(POSTS_PATH, post_folder.name)
  Dir.mkdir(post_folder_path) unless Dir.exist?(post_folder_path)

  CLIENT.list_folder(post_folder.path_display).entries.each do |file|
    CLIENT.download(file.path_display) do |content|
      File.write(File.join(POSTS_PATH, post_folder.name, file.name), content)
    end
  end
end

Dir.chdir(REPO_PATH) do
  run "git config --global user.email 'james+git@botanicus.me'"
  run "git config --global user.name 'Dropbox uploader'"
  run "git add #{POSTS_PATH}"
  run "git commit -a -m 'Updates'"
  run "git push origin master"
end
