#!/usr/bin/env ruby

# ../shared/runner.rb is copied to lib/runner.rb when rake build is run.
require_relative './lib/runner'

require 'dropbox_api'
require 'yaml'

RUNNER = Runner.new(__FILE__)
CLIENT = DropboxApi::Client.new(RUNNER.config.dropbox_access_token)

RUNNER.info("Running botanicus/dropbox-blog-publisher")

# Drop-folder handling.
drop_folder_items = CLIENT.list_folder(RUNNER.config.drop_folder)

if drop_folder_items.entries.empty?
  RUNNER.info("Nothing found in #{RUNNER.config.drop_folder}")
else
  main_post_file = drop_folder_items.entries.find { |file| file.name.match(/\.md$/) }
  slug = main_post_file.name.split('.').first
  RUNNER.info("Publishing #{slug}")

  # Add published date.
  begin
    CLIENT.download(main_post_file.path_display) do |content|
      content = content.force_encoding('utf-8')

      lines = content.split("\n")
      published_content = if content.include?('---')
        header = YAML.load(content)
        header['date'] ||= Time.now # Allow date to already be defined, as if we have published
        # en version and now we want to publish es version with the same date.
        [header.to_yaml.chomp.split("\n")[1..-1].join("\n"), '---', lines[(lines.index('---') + 1)..-1].join("\n")].join("\n\n")
      else
        header = {'date' => Time.now}
        [header.to_yaml.chomp.split("\n")[1..-1].join("\n"), '---', lines.join("\n")].join("\n\n")
      end

      path = main_post_file.path_display
      new_path = File.expand_path("#{main_post_file.path_display}/../post.md")
      RUNNER.info("Renaming #{slug}.md -> post.md and adding a timestamp")
      CLIENT.upload(new_path, "#{published_content.chomp}\n")
      CLIENT.delete(path)
    end

    RUNNER.notify(title: "Blog post #{slug} scheduled for publication")
  rescue Exception => error
    RUNNER.notify(title: "Post #{slug} cannot be published", message: "#{error.class}: #{error.message}")
  end

  drop_folder_items = CLIENT.list_folder(RUNNER.config.drop_folder)
  timestamp = Time.now.strftime('%Y-%m-%d')
  published_post_path = File.join(RUNNER.config.archive_folder, "#{timestamp}-#{slug}")

  RUNNER.info("Publishing #{published_post_path}")
  CLIENT.create_folder(published_post_path)
  drop_folder_items.entries.each do |file|
    RUNNER.info("Moving #{file.name} -> #{published_post_path}")
    CLIENT.move(file.path_display, File.join(published_post_path, file.name))
  end
end

published_files_request = CLIENT.list_folder(RUNNER.config.archive_folder)

if published_files_request.has_more?
  RUNNER.notify(title: "Blog error", message: "Dropbox pagination error, there might be missing files.")
  require 'pry'; binding.pry ###
end

# Download every published post from Dropbox and expose it on REPO_PATH.
Dir.mkdir('/root/.ssh')
File.write('/root/.ssh/id_rsa', RUNNER.config.private_ssh_key)

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

run "chmod 700 /root/.ssh"
run "chmod 600 /root/.ssh/id_rsa"
run "ssh-keyscan -H github.com >> /root/.ssh/known_hosts"
run "git config --global user.email 'james+git@botanicus.me'"
run "git config --global user.name 'Dropbox uploader'"

unless Dir.exist?("#{REPO_PATH}/.git")
  run "git clone #{RUNNER.config.repo} repo"
end

Dir.chdir(REPO_PATH) do
  run "git checkout ."
  run "git clean -fd"
  run "git pull --rebase"
  run "rm -rf #{POSTS_PATH}; mkdir #{POSTS_PATH}"

  published_files_request.entries.each do |post_folder|
    post_folder_path = File.join(POSTS_PATH, post_folder.name)
    Dir.mkdir(post_folder_path) unless Dir.exist?(post_folder_path)

    request = CLIENT.list_folder(post_folder.path_display)

    if request.has_more?
      RUNNER.notify(title: "Blog error", message: "Dropbox pagination error, there might be missing files.")
      require 'pry'; binding.pry ###
    end

    request.entries.each do |file|
      require 'pry'; binding.pry ###
      # if File.mtime()
      CLIENT.download(file.path_display) do |content|
        File.write(File.join(POSTS_PATH, post_folder.name, file.name), content)
      end
    end
  end

  run "git add #{POSTS_PATH}"
  run "git commit -a -m 'Updates'"
  run "git push origin master"
end
