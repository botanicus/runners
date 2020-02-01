#!/usr/bin/env ruby

# ../shared/runner.rb is copied to lib/runner.rb when rake build is run.
require_relative './lib/runner'

runner = Runner.new(__FILE__)
git_runner, dropbox_runner = GitRunner.new(runner), DropboxRunner.new(runner)

runner.info("Running dropbox-blog-publisher")
dropbox_runner.publish_drop_folder_entries

git_runner.setup_git
git_runner.within do
  xithing(dropbox_runner)
  commit_and_push
end
