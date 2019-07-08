#!/usr/bin/env ruby

require 'dropbox_api'
require 'logglier'
require 'yaml'

CONFIG = instance_eval(File.read(File.expand_path('../config.rb', __FILE__)))
LOGGER = Logglier.new(CONFIG.loggly_url, threaded: true)
CLIENT = DropboxApi::Client.new(CONFIG.dropbox_access_token)

LOGGER.info("Running botanicus/dropbox-servers-backup")

def run(command)
  puts "$ #{command}"
  result = %x{#{command}}
  puts result unless result.empty?
  if $?.exitstatus != 0
    abort "\nExited with #{$?.exitstatus}"
  end
end

# volume /backups
# rsync dev, rsync sys
Dir.chdir('/backups')

# run "test -d dev || mkdir dev"
# Dir.chdir('dev') do
#   run "rsync root@dev:/root/projects dev"
# end

run "test -d sys || mkdir sys"
Dir.chdir('sys') do
  run "cp -f /self/var/spool/cron/crontabs/root crontab"
end

backup_name = "#{Time.now.strftime('%Y-%m-%d')}.tbz"
run "tar cvjpf #{backup_name} *"

CLIENT.upload(File.join(CONFIG.backup_folder, backup_name), File.read(backup_name))
