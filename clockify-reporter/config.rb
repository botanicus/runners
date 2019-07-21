require 'ostruct'

OpenStruct.new(
  loggly_url: ENV.fetch('LOGGLY_URL'),
  clockify_api_key: ENV.fetch('CLOCKIFY_API_KEY'),
  target_hours_work_day: ENV.fetch('TARGET_HOURS_WORK_DAY'), # 9:20
  target_hours_saturday: ENV.fetch('TARGET_HOURS_SATURDAY'), # 4:20
  billing_cycle_start_date: ENV.fetch('BILLING_CYCLE_START_DATE'),
  hourly_rate: ENV.fetch('HOURLY_RATE'),
  pushover_app_token: ENV.fetch('PUSHOVER_APP_TOKEN'),
  pushover_user_key: ENV.fetch('PUSHOVER_USER_KEY')
)
