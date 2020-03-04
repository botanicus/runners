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
    # Generate SSH keys and put them to ~/.ssh/authorized_keys on dev.
    # Then:
    # Host dev
    #   HostName 134.209.47.239
    #   User root
    @runner.run("test -d dev || mkdir dev")
    Dir.chdir('dev') do
      @runner.run("rsync root@dev:/root/projects dev --recursive --delete")
    end

    @runner.run "test -d sys || mkdir sys"
    Dir.chdir('sys') do
      @runner.run("cp -f /self/var/spool/cron/crontabs/root crontab")
    end

    backup_name = "#{Time.now.strftime('%Y-%m-%d')}.tbz"
    @runner.run("tar cvjpf #{backup_name} *")

    @client.upload(File.join(@runner.config.backup_folder, backup_name), File.read(backup_name))

    @runner.run("rm #{backup_name}")
  end
end
