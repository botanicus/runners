class Runner
  def initialize(runner_file)
    @dir = File.dirname(runner_file)
  end

  def config
    @config ||= instance_eval(File.read(File.expand_path('config.rb', @dir)))
  end

  def logger
    @logger ||= begin
      require 'logglier'
      Logglier.new(self.validate_config_key('loggly_url'))
    end
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
    require 'pushover'

    clean_options = options.reduce(Hash.new) do |buffer, (key, value)|
      buffer.merge!(key => value) if value
      buffer
    end

    message = Pushover::Message.new(clean_options.merge(
      token: self.validate_config_key('pushover_app_token'),
      user: self.validate_config_key('pushover_user_key'),
    ))

    info("PushOver message: #{message.inspect}")

    begin
      response = message.push

      info("PushOver message delivery status: #{response.status == 1}")
      response.status == 1
    rescue => e
      p [:error, e]
    end
  end

  def notify_about_error(title, error)
    self.notify(
      title: title,
      message: {error: "#{error.class}: #{error.message}", trace: error.backtrace}.to_yaml
    )
  end

  def validate_config_key(key)
    if self.config.respond_to?(key)
      self.config.send(key)
    else
      raise "Runner#config #{self.config.inspect} doesn't have ##{key}"
    end
  end

  def sh(command)
    puts "$ #{command}"
    result = %x{#{command}}
    puts result unless result.empty?
    if $?.exitstatus != 0
      abort "\nExited with #{$?.exitstatus}"
    end
  end
end
