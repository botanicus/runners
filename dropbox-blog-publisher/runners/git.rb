# Download every published post from Dropbox and expose it on REPO_PATH.

class GitRunner
  REPO_PATH = '/repo'
  POSTS_PATH = '/repo/posts'
  OLD_POSTS_PATH = '/repo/old-posts'

  def initialize(runner)
    @runner = runner
  end

  # Used by runner.rb.
  def reset_git_repo
    @previous_head = `git rev-parse HEAD`.chomp
    system("git checkout .")
    system("git clean -fd")
    system("git pull --rebase")
  end

  # Used by runner.rb.
  def process(dropbox_runner)
    system("mv #{POSTS_PATH} #{OLD_POSTS_PATH}; mkdir #{POSTS_PATH}")

    notify_about_files_to_be_changed_in_dropbox unless self.changed_files.empty?

    dropbox_runner.published_entries.each do |post_folder|
      post_folder_path = File.join(POSTS_PATH, post_folder.name)
      Dir.mkdir(post_folder_path) unless Dir.exist?(post_folder_path)

      dropbox_runner.post_folder_entries(post_folder).each do |file|
        self.with_file(dropbox_runner, post_folder, file)
      end
    end
  end

  # Used by runner.rb.
  def commit_and_push
    @runner.sh("git add #{POSTS_PATH}")
    if system("git commit -a -m 'Updates'")
      @runner.sh("git push origin master")
    end
  end

  # Used by runner.rb.
  def setup_git
    @runner.info("Setting up SSH keys, Git user & repo.")
    setup_ssh_keys
    setup_git_user
    setup_git_repo
  end

  # Used by runner.rb.
  def with_repo(&block)
    @runner.info("Entering the repo directory.")
    Dir.chdir(REPO_PATH, &block)
  end

  protected
  def with_file(dropbox_runner, post_folder, file)
    post_path = File.join(POSTS_PATH, post_folder.name, file.name)
    old_post_path = File.join(OLD_POSTS_PATH, post_folder.name, file.name)


    if self.changed_files.include?(File.join('posts', post_folder.name, file.name)) # FIXME: hardcoded, but must be relative.
      # Handle manual updates in the data.blog repo.
      @runner.info("Updating #{post_path} in Dropbox")
      system("cp #{old_post_path} #{post_path}")
      dropbox_runner.update(file, File.binread(old_post_path))
    elsif File.exist?(old_post_path) && (file.server_modified.to_date != File.mtime(old_post_path).to_date) # This is not exact, it always re-downloads post from current day, but Dropbox returns weird timestamps, so I guess it's sufficient.
      # Handle unchanged posts.
      system("cp #{old_post_path} #{post_path}")
    else
      # Handle newly published posts (as in, posts just moved from the drop folder).
      @runner.info("Updating #{post_path} from Dropbox")
      # FIXME: We should notify about updates, but since the posts are re-downloaded (see the previous elsif branch), we are not sure if there really has been an update.
      content = dropbox_runner.load_entry(file)
      File.write(post_path, content)
    end
  end

  def setup_ssh_keys
    Dir.mkdir('/root/.ssh')
    File.write('/root/.ssh/id_rsa', @runner.config.private_ssh_key)
    system("chmod 700 /root/.ssh")
    system("chmod 600 /root/.ssh/id_rsa")
  end

  def setup_git_user
    system("git config --global user.email '#{@runner.config.git_email}'")
    system("git config --global user.name '#{@runner.config.git_name}'")
  end

  def setup_git_repo
    system("ssh-keyscan -H github.com >> /root/.ssh/known_hosts 2> /dev/null")

    unless Dir.exist?("#{REPO_PATH}/.git")
      @runner.sh("git clone #{@runner.config.repo} repo")
    end
  end

  def notify_about_files_to_be_changed_in_dropbox
    @runner.notify(
      title: "Manually updated blog entries will be changed in Dropbox",
      message: changed_files.join(', ')
    )
  end

  def changed_files
    `git diff --name-only #{@previous_head} HEAD posts/`.lines.map(&:chomp)
  end
end
