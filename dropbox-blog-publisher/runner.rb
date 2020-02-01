#!/usr/bin/env ruby

# ../shared/runner.rb is copied to lib/runner.rb when rake build is run.
require_relative './lib/runner'

require_relative './runners/git'
require_relative './runners/dropbox'

Runner.run(__FILE__) do |runner|
  git_runner, dropbox_runner = GitRunner.new(runner), DropboxRunner.new(runner)

  runner.info("Running dropbox-blog-publisher.")
  dropbox_runner.publish_drop_folder_entries

  git_runner.setup_git
  git_runner.with_repo do
    git_runner.reset_git_repo
    git_runner.process(dropbox_runner)
    git_runner.commit_and_push
  end
end
