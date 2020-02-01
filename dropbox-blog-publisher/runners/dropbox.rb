require 'dropbox_api'
require 'yaml'
require 'time'

class Post
  def self.parse(content)
    lines = content.force_encoding('utf-8').split("\n")

    if content.include?('---')
      header = YAML.load(content)
      header['date'] ||= Time.now
      self.new(header, lines[(lines.index('---') + 2)..-1])
    else
      header = {'date' => Time.now}
      self.new(header, lines)
    end
  end

  attr_reader :header, :lines
  def initialize(header, lines)
    @header, @lines = header, lines
  end

  def to_s
    [@header.to_yaml.chomp.split("\n")[1..-1].join("\n"), '---', @lines.join("\n")].join("\n\n")
  end
end

class DropboxRunner
  def initialize(runner)
    @runner, @dropbox = runner, DropboxApi::Client.new(runner.config.dropbox_access_token)
  end

  # Used by the GitRunner.
  def post_folder_entries(post_folder)
    self.get_entries(post_folder.path_display)
  end

  # Used by the GitRunner.
  def published_entries
    self.get_entries(@runner.config.archive_folder)
  end

  # Used by the GitRunner.
  def update(file, content)
    @dropbox.delete(file.path_display)
    @dropbox.upload(file.path_display, content)
  end

  # Used by the GitRunner.
  def load_entry(file)
    @dropbox.download(file.path_display) { |content| return content }
  end

  # User by runner.rb.
  def publish_drop_folder_entries
    drop_folder_items = @dropbox.list_folder(@runner.config.drop_folder)

    if drop_folder_items.entries.empty?
      @runner.info("Nothing found in #{@runner.config.drop_folder}.")
    else
      drop_folder_items.entries.select { |file| file.name.match(/\.md$/) }.each do |main_post_file|
        self.publish_file(main_post_file)
      end
    end
  end

  protected
  def publish_file(main_post_file)
    slug = main_post_file.name.split('.').first

    content = self.dropbox_read_file(main_post_file.path_display)
    post = Post.parse(content)

    published_date_timestamp = post.header['date'].strftime('%Y-%m-%d')
    self.move_to_published_posts_in_dropbox(main_post_file.path_display, published_date_timestamp, slug, post)
  rescue Exception => error
    @runner.notify_about_error("Post #{slug} cannot be published", error)
  end

  def move_to_published_posts_in_dropbox(old_file_path, timestamp, slug, post)
    published_post_path = File.join(@runner.config.archive_folder, "#{timestamp}-#{slug}")

    @runner.info("Publishing #{published_post_path}")

    @dropbox.create_folder(published_post_path)
    @dropbox.upload("#{published_post_path}/post.md", "#{post.to_s}\n")
    @dropbox.delete(old_file_path)

    self.copy_assets(published_post_path)

    @runner.notify(title: "Blog post #{slug} scheduled for publication", message: post.inspect)
  end

  def copy_assets(destination)
    drop_folder_items = @dropbox.list_folder(@runner.config.drop_folder)
    drop_folder_items.entries.each do |file|
      @runner.info("Moving #{file.name} -> #{published_post_path}")
      @dropbox.move(file.path_display, File.join(destination, file.name))
    end
  end

  def dropbox_read_file(path)
    @dropbox.download(path) { |content| return content }
  end

  def get_entries(path)
    @dropbox.list_folder(path).tap { |request| guard(request) }.entries
  end

  def guard(request)
    if request.has_more?
      @runner.notify(title: "Blog error", message: "Dropbox pagination error, there might be missing files.")
      require 'pry'; binding.pry ###
    end
  end
end
