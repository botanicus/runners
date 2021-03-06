require 'pry'
require 'yaml'
require 'pushover'
require 'logglier'

class Runner
  def self.run(runner_file, &block)
    runner = self.new(runner_file)
    block.call(runner)
  rescue Exception => error
    runner.notify_about_error("An error occured in a runner", error)
  end

  def initialize(runner_file)
    @dir = File.dirname(runner_file)
  end

  def config
    @config ||= instance_eval(File.read(File.expand_path('config.rb', @dir)))
  end

  def logger
    @logger ||= Logglier.new(self.validate_config_key('loggly_url'))
  end

  def info(message)
    puts "~ #{message}"
    self.logger.info(message)
  end

  def warn(message)
    puts "~ #{message}"
    self.logger.warn(message)
  end

  def run(command)
    puts "$ #{command}"
    result = %x{#{command}}
    puts result unless result.empty?
    if $?.exitstatus != 0
      abort "\nExited with #{$?.exitstatus}"
    end
  end

  # # Until https://github.com/erniebrodeur/pushover/issues/34 is fixed
  # def notify(**options)
  #   command = %Q{curl -s --form-string "token=#{self.validate_config_key('pushover_app_token')}" --form-string "user=#{self.validate_config_key('pushover_user_key')}" --form-string "title=#{options[:title]}" --form-string "message=#{options[:message]}" https://api.pushover.net/1/messages.json}
  #   puts command
  #   system command
  # end

  # notify(
  #   title: "Instapaper article expired",
  #   message: bookmark.title,
  #   url: bookmark.url
  # )
  def notify(quiet: false, **options)
    clean_options = options.reduce(Hash.new) do |buffer, (key, value)|
      buffer.merge!(key => value) if value
      buffer
    end

    message = Pushover::Message.new(clean_options.merge(
      token: self.validate_config_key('pushover_app_token'),
      user: self.validate_config_key('pushover_user_key'),
    ))

    self.info("PushOver message: #{clean_options.inspect}") unless quiet

    begin
      response = message.push

      self.info("PushOver message delivery status: #{response.status == 1}")
      response.status == 1
    rescue => e
      self.warn("Frozen excon error, delivery should succeed nevertheless though.")
    end
  end

  def notify_about_error(title, error)
    self.notify(
      title: title,
      message: {error: "#{error.class}: #{error.message}", trace: error.backtrace}.to_yaml,
      quiet: true
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
