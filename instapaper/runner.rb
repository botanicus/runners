#!/usr/bin/env ruby

# ../shared/runner.rb is copied to lib/runner.rb when rake build is run.
require_relative './lib/runner'

require_relative './runners/instapaper'

Runner.run(__FILE__) do |runner|
  instapaper_runner = InstapaperRunner.new(runner)

  bookmarks = instapaper_runner.fetch_first_500_bookmarks
  old_bookmarks = instapaper_runner.filter_old_bookmarks(bookmarks)
  instapaper_runner.notify_about_too_many_old_bookmarks(bookmarks, old_bookmarks)
  instapaper_runner.delete_configured_number_of_old_bookmarks_and_notify(old_bookmarks)
end
