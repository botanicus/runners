require 'logglier'
require 'pushover'

class Runner
  def new(runner_file)
    @dir = File.dirname(runner_file)
  end

  def config
    @config ||= instance_eval(File.read(File.join('config.rb', @dir)))
  end

  def logger
    @logger ||= Logglier.new(self.validate_config_key('loggly_url'), threaded: true)
  end

  def info(message)
    puts "~ #{message}"
    self.logger.info(message)
  end

  def warn(message)
    puts "~ #{message}"
    self.logger.warn(message)
  end

  # notify(
  #   title: "Instapaper article expired",
  #   message: bookmark.title,
  #   url: bookmark.url
  # )
  def notify(**options)
    clean_options = options.reduce(Hash.new) do |buffer, (key, value)|
      buffer.merge!(key => value) if value
      buffer
    end

    message = Pushover::Message.create(clean_options.merge(
      token: self.validate_config_key('pushover_app_token'),
      user: self.validate_config_key('pushover_user_key'),
    ))

    info("PushOver message: #{message.inspect}")

    response = message.push
    info("PushOver message delivery status: #{response.status == 1}")
    response.status == 1
  end

  def validate_config_key(key)
    if self.config.respond_to?(key)
      self.config.send(key)
    else
      raise "Config doesn't have ##{key}"
    end
  end
end
