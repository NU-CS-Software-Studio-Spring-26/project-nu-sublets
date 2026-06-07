module CentralTimeFormatting
  CENTRAL_TIME_ZONE = "America/Chicago".freeze
  CENTRAL_TIME_LABEL = "CT".freeze

  def central_time(time)
    time&.in_time_zone(CENTRAL_TIME_ZONE)
  end

  def format_central_time(time, format:, include_label: false)
    return "" if time.blank?

    formatted_time = central_time(time).strftime(format)
    include_label ? "#{formatted_time} #{CENTRAL_TIME_LABEL}" : formatted_time
  end
end
