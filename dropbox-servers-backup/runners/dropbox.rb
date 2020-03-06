require 'dropbox_api'


class DropboxRunner
  def initialize(runner)
    @runner, @client = runner, DropboxApi::Client.new(runner.config.dropbox_access_token)
  end

  def in_backups(&block)
    # volume /backups
    # rsync dev, rsync sys
    Dir.chdir('/backups', &block)
  end

  def run
    @runner.config.servers.each do |(name, ip)|
      @runner.run("test -d #{name} || mkdir #{name}")
      @runner.run("rsync root@#{ip}:/root/projects #{name} --recursive --delete") # FIXME: backup locations should be configurable.
    end

    @runner.run("test -d sys || mkdir sys")
    # TODO: also make configurable.
    Dir.chdir('sys') do
      @runner.run("cp -f /self/var/spool/cron/crontabs/root crontab")
      @runner.run("rm -rf cron")
      @runner.run("cp -R /self/root/cron cron")
    end

    backup_name = "#{Time.now.strftime('%Y-%m-%d')}.tbz"
    @runner.run("tar cvjpf #{backup_name} #{@runner.config.servers.keys.join(' ')} sys")

    @client.upload(File.join(@runner.config.backup_folder, backup_name), File.read(backup_name))

    @runner.run("rm #{backup_name}")
  end
end
