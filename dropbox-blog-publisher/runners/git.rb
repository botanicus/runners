# Download every published post from Dropbox and expose it on REPO_PATH.

REPO_PATH = '/repo'
POSTS_PATH = '/repo/posts'
OLD_POSTS_PATH = '/repo/old-posts'

class GitRunner
  def initialize(runner, dropbox)
    @runner, @dropbox = runner, dropbox
  end

  def setup_ssh_keys
    @runner.info("Setting up SSH keys.")
    Dir.mkdir('/root/.ssh')
    File.write('/root/.ssh/id_rsa', @runner.config.private_ssh_key)
    @runner.sh("chmod 700 /root/.ssh", quiet: true)
    @runner.sh("chmod 600 /root/.ssh/id_rsa", quiet: true)
  end

  def setup_git_user
    @runner.info("Setting up Git user.")
    @runner.sh("git config --global user.email 'james+git@jakubstastny.me'", quiet: true)
    @runner.sh("git config --global user.name 'Dropbox uploader'", quiet: true)
  end

  def setup_git_repo
    @runner.info("Setting up Git repo.")
    @runner.sh("ssh-keyscan -H github.com >> /root/.ssh/known_hosts", quiet: true)

    unless Dir.exist?("#{REPO_PATH}/.git")
      @runner.sh("git clone #{@runner.config.repo} repo")
    end
  end

  def xithing(dropbox_runner)
    changed_files = get_changed_files

    @runner.sh("mv #{POSTS_PATH} #{OLD_POSTS_PATH}; mkdir #{POSTS_PATH}", quiet: true)

    notify_about_files_to_be_changed_in_dropbox

    dropbox_runner.published_files.each do |post_folder|
      post_folder_path = File.join(POSTS_PATH, post_folder.name)
      Dir.mkdir(post_folder_path) unless Dir.exist?(post_folder_path)

      dropbox_runner.list_folder(post_folder.path_display)

      request.entries.each do |file|
        with_file(file)
      end
    end
  end

  def commit_and_push
    @runner.sh("git add #{POSTS_PATH}")
    @runner.sh("git commit -a -m 'Updates' && git push origin master || exit") # This is so this never fails.
  end

  def notify_about_files_to_be_changed_in_dropbox
    unless changed_files.empty?
      @runner.notify(
        title: "Manually updated blog entries will be changed in Dropbox",
        message: changed_files.join(', ')
      )
    end
  end

  def setup_git
    setup_ssh_keys
    setup_git_user
    setup_git_repo
  end

  def within(&block)
    Dir.chdir(REPO_PATH, &block)
  end

  def with_file(file)
    post_path = File.join(POSTS_PATH, post_folder.name, file.name)
    old_post_path = File.join(OLD_POSTS_PATH, post_folder.name, file.name)

    if changed_files.include?(File.join('posts', post_folder.name, file.name)) # FIXME: hardcoded, but must be relative.
      @runner.info("Updating #{file.path_display} in Dropbox")
      @runner.sh "cp #{old_post_path} #{post_path}"
      @dropbox.delete(file.path_display)
      @dropbox.upload(file.path_display, File.binread(old_post_path))
    else
      @runner.sh "cp #{old_post_path} #{post_path}"
    end
  end

  protected
  def get_changed_files
    previous_head = `git rev-parse HEAD`.chomp

    @runner.sh("git checkout .", quiet: true)
    @runner.sh("git clean -fd", quiet: true)
    @runner.sh("git pull --rebase", quiet: true)

    `git diff --name-only #{previous_head} HEAD posts/`.lines.map(&:chomp)
  end
end

