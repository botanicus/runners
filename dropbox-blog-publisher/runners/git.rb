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
    @runner.sh("git checkout .", quiet: true)
    @runner.sh("git clean -fd", quiet: true)
    @runner.sh("git pull --rebase", quiet: true)
  end

  # Used by runner.rb.
  def process(dropbox_runner)
    @runner.sh("mv #{POSTS_PATH} #{OLD_POSTS_PATH}; mkdir #{POSTS_PATH}", quiet: true)

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
    @runner.sh("git commit -a -m 'Updates' && git push origin master || exit") # This is so this never fails.
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

    @runner.info("Processing #{post_path}")

    if self.changed_files.include?(File.join('posts', post_folder.name, file.name)) # FIXME: hardcoded, but must be relative.
      # Handle manual updates in the data.blog repo.
      @runner.info("Updating #{file.path_display} in Dropbox")
      @runner.sh("cp #{old_post_path} #{post_path}", quiet: true)
      dropbox_runner.update(file, File.binread(old_post_path))
    elsif File.exist?(old_post_path)
      # Handle unchanged posts.
      @runner.sh("cp #{old_post_path} #{post_path}", quiet: true)
    else
      # Handle newly published posts (as in, posts just moved from the drop folder).
      content = dropbox_runner.load_entry(file)
      File.write(post_path, content)
    end
  end

  def setup_ssh_keys
    Dir.mkdir('/root/.ssh')
    File.write('/root/.ssh/id_rsa', @runner.config.private_ssh_key)
    @runner.sh("chmod 700 /root/.ssh", quiet: true)
    @runner.sh("chmod 600 /root/.ssh/id_rsa", quiet: true)
  end

  def setup_git_user
    @runner.sh("git config --global user.email 'james+git@jakubstastny.me'", quiet: true)
    @runner.sh("git config --global user.name 'Dropbox uploader'", quiet: true)
  end

  def setup_git_repo
    @runner.sh("ssh-keyscan -H github.com >> /root/.ssh/known_hosts 2> /dev/null", quiet: true)

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
