require 'dropbox_api'
require 'yaml'

class DropboxRunner
  def initialize(runner)
    @runner, @dropbox = runner, DropboxApi::Client.new(runner.config.dropbox_access_token)
  end

  # Used by the GitRunner.
  def list_folder(path)
    @dropbox.list_folder(path).tap do |request|
      guard(request)
    end
  end

  # Used by the GitRunner.
  def published_files
    published_files_request = @dropbox.list_folder(@runner.config.archive_folder)
    guard(published_files_request)
    published_files_request.entries
  end

  # User by runner.rb.
  def publish_drop_folder_entries
    drop_folder_items = @dropbox.list_folder(@runner.config.drop_folder)

    if drop_folder_items.entries.empty?
      @runner.info("Nothing found in #{@runner.config.drop_folder}")
    else
      main_post_file = drop_folder_items.entries.find { |file| file.name.match(/\.md$/) }
      slug = main_post_file.name.split('.').first
      @runner.notify(title: "Publishing #{slug}")
      @runner.info("Publishing #{slug}")

      publish_post(main_post_file)

      drop_folder_items = @dropbox.list_folder(@runner.config.drop_folder)
      timestamp = Time.now.strftime('%Y-%m-%d')
      published_post_path = File.join(@runner.config.archive_folder, "#{timestamp}-#{slug}")

      @runner.info("Publishing #{published_post_path}")
      @dropbox.create_folder(published_post_path)
      drop_folder_items.entries.each do |file|
        @runner.info("Moving #{file.name} -> #{published_post_path}")
        @dropbox.move(file.path_display, File.join(published_post_path, file.name))
      end
    end
  end

  protected
  def publish_post(main_post_file)
    @dropbox.download(main_post_file.path_display) do |content|
      content = content.force_encoding('utf-8')

      lines = content.split("\n")
      published_content = if content.include?('---')
        header = YAML.load(content)
        header['date'] ||= Time.now # Allow date to already be defined, as if we have published
        # en version and now we want to publish es version with the same date.
        [header.to_yaml.chomp.split("\n")[1..-1].join("\n"), '---', lines[(lines.index('---') + 1)..-1].join("\n")].join("\n\n")
        p header.to_yaml.chomp.split("\n")[1..-1]
        puts; puts; puts
        p lines[(lines.index('---') + 1)..-1]
        puts; puts; puts
      else
        header = {'date' => Time.now}
        [header.to_yaml.chomp.split("\n")[1..-1].join("\n"), '---', lines.join("\n")].join("\n\n")
      end

      path = main_post_file.path_display
      new_path = File.expand_path("#{main_post_file.path_display}/../post.md")
      @runner.info("Renaming #{slug}.md -> post.md and adding a timestamp")
      @dropbox.upload(new_path, "#{published_content.chomp}\n")
      @dropbox.delete(path)
    end

    @runner.notify(title: "Blog post #{slug} scheduled for publication")
  rescue Exception => error
    @runner.notify(title: "Post #{slug} cannot be published", message: "#{error.class}: #{error.message}")
  end

  def guard(request)
    if request.has_more?
      @runner.notify(title: "Blog error", message: "Dropbox pagination error, there might be missing files.")
      require 'pry'; binding.pry ###
    end
  end
end
