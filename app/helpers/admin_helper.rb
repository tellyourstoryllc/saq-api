module AdminHelper
  TIME_FORMATS = {long: '%B %-d, %Y %l:%M %P %Z',
                  short: '%m/%d/%y %l:%M %P'}

  def alert_class(type)
    case type.to_s
    when 'info'
      # Blue.
      'alert-info'
    when 'error', 'alert'
      # Red.
      'alert-danger'
    else
      # Yellow.
      'alert-warning'
    end
  end

  def link_to_google_maps(text, lat, lon, options = {})
    link_to text, "https://www.google.com/maps/search/#{lat},#{lon}", options
  end

  def admin_timestamp(datetime, options = {})
    return datetime unless datetime

    format = TIME_FORMATS[options[:format] || :long]

    str = datetime.in_time_zone('Eastern Time (US & Canada)')
    str = str.strftime(format)
    str += " (#{time_ago_in_words datetime} ago)" if options[:time_ago]

    str
  end
end
