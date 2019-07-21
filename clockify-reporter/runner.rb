#!/usr/bin/env ruby

require 'http'
require 'date'
require 'json'
require 'hour'
require 'pushover'
require 'logglier'

# TODO: Implement #to_s reasonably in the gem itself.
class Hour
  def to_s
    [@h, format('%02d', @m)].join(':')
  end
end


CONFIG = instance_eval(File.read(File.expand_path('../config.rb', __FILE__)))
LOGGER = Logglier.new(CONFIG.loggly_url, threaded: true)

# Helpers.
def info(message)
  puts "~ #{message}"
  LOGGER.info(message)
end

def warn(message)
  puts "~ #{message}"
  LOGGER.warn(message)
end

def make_request(http_method, path)
  request = HTTP.headers({'Content-Type' => 'application/json', 'X-Api-Key' => API_KEY})
  JSON.parse(request.send(http_method, "https://api.clockify.me/api/v1/#{path}").body.to_s)
end

def hours_projected_for_date(date)
  if date.sunday?
    Hour.new
  elsif date.saturday?
    Hour.parse(CONFIG.target_hours_saturday)
  else
    Hour.parse(CONFIG.target_hours_work_day)
  end
end

def billing_cycle(start_date)
  if start_date + 14 >= Date.today
    return start_date, start_date + 14
  else
    billing_cycle(start_date + 14)
  end
end

def notify(**options)
  clean_options = options.reduce(Hash.new) do |buffer, (key, value)|
    buffer.merge!(key => value) if value
    buffer
  end

  message = Pushover::Message.create(clean_options.merge(
    token: CONFIG.pushover_app_token,
    user: CONFIG.pushover_user_key,
  ))

  info("PushOver message: #{message.inspect}")

  response = message.push
  info("PushOver message delivery status: #{response.status == 1}")
  response.status == 1
end

# Main.
info("Running botanicus/#{File.basename(Dir.pwd)}") # TODO: propagate this version to the other runners.

from_date, to_date = billing_cycle(Date.parse(CONFIG.billing_cycle_start_date))

user_id = make_request(:get, '/user')['id']
memberships = make_request(:get, '/workspaces')[0]['memberships']
workspace_ids = memberships.select { |m| m['membershipStatus'] == 'ACTIVE' }.map { |m| m['targetId'] }.uniq

entries = workspace_ids.map do |workspace_id|
  make_request(:get, "/workspaces/#{workspace_id}/user/#{user_id}/time-entries")
end.flatten

entries_within_time_range = entries.select do |entry|
  from_date <= Date.parse(entry['timeInterval']['start'])
end

total_minutes = entries_within_time_range.reduce(0) do |sum, entry|
  if entry['timeInterval']['duration']
    start_time = Time.parse(entry['timeInterval']['start'])
    end_time = Time.parse(entry['timeInterval']['end'])
    duration = end_time - start_time
  else
    start_time = Time.parse(entry['timeInterval']['start'])
    duration = Time.now - start_time
  end

  sum + (duration / 60).to_i
end

hours_projected_to_date = (from_date..Date.today).reduce(Hour.new) do |sum, date|
  sum + hours_projected_for_date(date)
end

hours_worked = Hour.from(minutes: total_minutes)
sum_made = total_minutes * CONFIG.hourly_rate.to_i / 60

# Today
hours_projected_for_today = hours_projected_for_date(Date.today)

# if hours_worked_today < hours_projected_for_today
#   p title: "You made $#{sum_made_today} today", message: "You were #{hours_projected_for_today - hours_worked_today} off the target.", html: 1
# else
#   p title: "Good job! You hit the target for today!", message: "You made <b>$#{sum_made_today}</b> today. Nice!", html: 1
# end

if hours_worked < hours_projected_to_date
  p title: "Stay on the target!", message: "You are off the target by <b>#{hours_projected_to_date - hours_worked}</b> hours. You made <b>$#{sum_made}</b> from #{from_date.strftime('%A %d/%m')}.", html: 1
else
  p title: "Good job! You're on the target!", message: "You are exceeding the target by <b>#{hours_worked - hours_projected_to_date}</b>. You made <b>$#{sum_made}</b> from #{from_date.strftime('%A %d/%m')}.", html: 1
end
