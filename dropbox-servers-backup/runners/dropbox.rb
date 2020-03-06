require 'dropbox_api'
require 'json'

class DropboxRunner
  def initialize(runner)
    @runner, @client = runner, DropboxApi::Client.new(runner.config.dropbox_access_token)
  end

  def verify_servers
    # TODO: verify it's a hash, verify its values.
    self.servers
  rescue
    binding.pry
  end

  def in_backups(&block)
    Dir.chdir('/backups', &block)
  end

  def run
    self.servers.each do |(name, server)|
      @runner.run("test -d #{name} || mkdir #{name}")
      server['paths'].each do |path|
        @runner.run("rsync #{[server['machine'], path].compact.join(':')} #{name} --recursive --delete")
      end
    end

    # @runner.run("test -d sys || mkdir sys")
    # Dir.chdir('sys') do
    #   @runner.run("cp -f /self/var/spool/cron/crontabs/root crontab")
    #   @runner.run("rm -rf cron")
    #   @runner.run("cp -R /self/root/cron cron")
    # end

    backup_name = "#{Time.now.strftime('%Y-%m-%d')}.tbz"
    @runner.run("tar cjpf #{backup_name} #{self.servers.keys.join(' ')} sys")

    @client.upload(File.join(@runner.config.backup_folder, backup_name), File.read(backup_name))

    @runner.run("rm #{backup_name}")
  end

  protected
  def servers
    @servers ||= JSON.parse(@runner.config.servers)
  end
end
