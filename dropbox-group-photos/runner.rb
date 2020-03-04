#!/usr/bin/env ruby

# ../shared/runner.rb is copied to lib/runner.rb when rake build is run.
require_relative './lib/runner'

require_relative './runners/dropbox'

Runner.run(__FILE__) do |runner|
  dropbox_runner = DropboxRunner.new(runner)

  photos = dropbox_runner.list_photos
  old_photos = dropbox_runner.filter_old_photos(photos)

  runner.info("There are #{old_photos.length} files older than #{runner.config.days_to_keep} days of #{photos.length} camera uploads")

  dropbox_runner.create_folders(old_photos)
  dropbox_runner.archive_old_photos(old_photos)
end
