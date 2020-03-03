require 'instapaper'

class InstapaperRunner
  def initialize(runner)
    @runner = runner
  end

  def client
    @client ||= begin
      Instapaper::Client.new do |client|
        client.consumer_key = @runner.config.instapaper_client_key
        client.consumer_secret = @runner.config.instapaper_client_secret

        token = client.access_token(@runner.config.instapaper_username, @runner.config.instapaper_password)
        client.oauth_token = token.oauth_token
        client.oauth_token_secret = token.oauth_token_secret
      end
    end
  end

  def fetch_first_500_bookmarks
    self.client.bookmarks(limit: 500).bookmarks.tap do |bookmarks|
      if bookmarks.length > 499
        warn("Warning: only first 500 bookmarks are being inspected.")
      end
    end
  end

  def filter_old_bookmarks(bookmarks)
    bookmarks.filter do |bookmark|
      # Take the more recent timestamp (save time or last progress time)
      # and compare with the days_to_keep variable.
      timestamp = [bookmark.time, bookmark.progress_timestamp].sort.last
      timestamp < (Date.today - @runner.config.days_to_keep)
    end
  end

  def notify_about_too_many_old_bookmarks(bookmarks, old_bookmarks)
    @runner.info("Out of #{bookmarks.length} bookmarks, #{old_bookmarks.length} are older than #{@runner.config.days_to_keep} days")
    if old_bookmarks.length > @runner.config.max_bookmarks_at_once
      message = "Maximum number of bookmarks to be processed at once is #{@runner.config.max_bookmarks_at_once}. Keeping the rest #{old_bookmarks.length - @runner.config.max_bookmarks_at_once} for later."
      warn(message)
      @runner.notify(
        title: "There are too many expired articles in your Instapaper",
        message: message
      )
    end
  end

  def delete_configured_number_of_old_bookmarks_and_notify(old_bookmarks)
    old_bookmarks[0...@runner.config.max_bookmarks_at_once].each do |bookmark|
      self.delete_bookmark(bookmark) if notify_about_deletion(bookmark)
    end
  end

  protected
  def delete_bookmark(bookmark)
    if self.client.delete_bookmark(bookmark.bookmark_id)
      @runner.info("DELETE #{bookmark.title} – #{bookmark.url}")
    end
  end

  def notify_about_deletion(bookmark)
    @runner.notify(
      title: "Instapaper article expired",
      message: bookmark.title,
      url: bookmark.url
    )
  end
end
