#!/usr/bin/env ruby

require 'dropbox_api'
require 'logglier'
require 'yaml'
require 'date'

CONFIG = instance_eval(File.read(File.expand_path('../config.rb', __FILE__)))
LOGGER = Logglier.new(CONFIG.loggly_url, threaded: true)
CLIENT = DropboxApi::Client.new(CONFIG.dropbox_access_token)

ALLOWED_WIP_ITEMS = ['Personal', 'Trabajo']
ALLOWED_WORK_ITEMS = ['README.md']
ALLOWED_PERSONAL_ITEMS = []

LOGGER.info("Running botanicus/dropbox-wip-cleaner")

# WIP
wip_folder_items = CLIENT.list_folder(CONFIG.wip_folder)
not_allowed_root_items = wip_folder_items.entries.select { |e| not ALLOWED_WIP_ITEMS.include?(e.name) }

not_allowed_root_items.each do |path|
  LOGGER.info("Moving #{path.name} to Personal")
  CLIENT.move(path.path_display, File.join(CONFIG.wip_folder, 'Personal', path.name))
end

# WIP/Trabajo
work_folder_items = CLIENT.list_folder(File.join(CONFIG.wip_folder, 'Trabajo'))
not_allowed_work_items = work_folder_items.entries.select { |e| not ALLOWED_WORK_ITEMS.include?(e.name) }

not_allowed_root_items.each do |path|
  if path.server_modified < (Date.today - 20).to_time
    # TOO OLD, delete
    # LOGGER.info("Moving #{path.name} to Personal")
  else
    # notify
    # LOGGER.info("Moving #{path.name} to Personal")
  end
end

# WIP/Personal

require 'pry'; binding.pry ###
