module CentralTimeHelper
  CENTRAL_TIME_ZONE = "America/Chicago".freeze
  CENTRAL_TIME_LABEL = "CT".freeze
  CENTRAL_TIME_DISPLAY_FORMAT = "%b %-d, %Y %-l:%M %p #{CENTRAL_TIME_LABEL}".freeze

  def self.format_central_time(time)
    return "" if time.blank?

    time.in_time_zone(CENTRAL_TIME_ZONE).strftime(CENTRAL_TIME_DISPLAY_FORMAT)
  end

  def self.central_time_display(time)
    format_central_time(time)
  end

  def format_central_time(time)
    CentralTimeHelper.format_central_time(time)
  end

  def central_time_display(time)
    format_central_time(time)
  end
end
