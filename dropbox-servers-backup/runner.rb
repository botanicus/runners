#!/usr/bin/env ruby

# ../shared/runner.rb is copied to lib/runner.rb when rake build is run.
require_relative './lib/runner'

require_relative './runners/dropbox'

Runner.run(__FILE__) do |runner|
  dropbox_runner = DropboxRunner.new(runner)

  dropbox_runner.verify_servers
  dropbox_runner.in_backups do
    dropbox_runner.run
  end
end
