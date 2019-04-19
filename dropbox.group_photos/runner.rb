#!/usr/bin/env ruby

require 'dropbox_api'

CONFIG = instance_eval(File.read(File.expand_path('../config.rb', __FILE__)))

client = DropboxApi::Client.new(CONFIG.dropbox_access_token)
camera_uploads = client.list_folder('/Camera Uploads')
camera_upload_files = camera_uploads.entries.select { |entry| entry.respond_to?(:rev) }
# We have client_modified, server_modified and format of the file.
# The file might be named differently than expected though.
old_camera_upload_files = camera_upload_files.select { |file| file.server_modified < (Time.now - (60 * 60 * 24 * CONFIG.keep_days)) }

folders_to_be_created = old_camera_upload_files.map { |file| file.server_modified.strftime('%Y-%m') }.uniq
folders_to_be_created.each do |folder|
  folder_path = "/#{File.join(CONFIG.parent_folder, folder)}"
  puts "~ Creating folder #{folder_path}"
  client.create_folder(folder_path)
rescue DropboxApi::Errors::FolderConflictError
end

old_camera_upload_files.each do |file|
  destination_file = "/#{File.join(CONFIG.parent_folder, file.server_modified.strftime('%Y-%m'))}/#{file.name}"
  puts "~ Moving #{file.path_display} to #{destination_file}"
  client.move(file.path_display, destination_file)
end
