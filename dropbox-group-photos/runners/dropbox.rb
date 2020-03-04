require 'dropbox_api'


class DropboxRunner
  def initialize(runner)
    @runner, @client = runner, DropboxApi::Client.new(runner.config.dropbox_access_token)
  end

  def list_photos
    self.retrieve_photos(@client.list_folder('/Camera Uploads'))
  end

  # We have client_modified, server_modified and format of the file.
  # The file might be named differently than expected though.
  def filter_old_photos(photos)
    photos.select do |file|
      file.server_modified < (Time.now - (60 * 60 * 24 * @runner.config.days_to_keep))
    end
  end

  def create_folders(old_photos)
    folders_to_be_created = old_photos.map { |file| file.server_modified.strftime('%Y-%m') }.uniq
    folders_to_be_created.each do |folder|
      folder_path = "/#{File.join(@runner.config.parent_folder, folder)}"
      @runner.info("Creating folder #{folder_path}")
      @client.create_folder(folder_path)
    rescue DropboxApi::Errors::FolderConflictError
    end
  end

  def archive_old_photos(old_photos)
    old_photos.each do |file|
      destination_file = "/#{File.join(@runner.config.parent_folder, file.server_modified.strftime('%Y-%m'))}/#{file.name}"
      @runner.info("Moving #{file.path_display} to #{destination_file}")
      @client.move(file.path_display, destination_file)
    end
  end

  protected
  def retrieve_photos(response)
    if response.has_more?
      response = @client.list_folder_continue(response.cursor)
      self.retrieve_photos(response)
    end

    response.entries.select { |entry| entry.respond_to?(:rev) }
  end
end
