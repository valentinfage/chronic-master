require 'time'
require 'date'
require 'numerizer'

require_relative 'chronic/version'

require_relative 'chronic/parser'
require_relative 'chronic/date'
require_relative 'chronic/time'

require_relative 'chronic/handler'
require_relative 'chronic/handlers'
require_relative 'chronic/mini_date'
require_relative 'chronic/span'
require_relative 'chronic/token'
require_relative 'chronic/tokenizer'
require_relative 'chronic/season'

require_relative 'chronic/tag'
require_relative 'chronic/tags/grabber'
require_relative 'chronic/tags/ordinal'
require_relative 'chronic/tags/pointer'
require_relative 'chronic/tags/scalar'
require_relative 'chronic/tags/separator'
require_relative 'chronic/tags/sign'
require_relative 'chronic/tags/time_zone'

require_relative 'chronic/tags/repeater'
require_relative 'chronic/repeaters/repeater_year'
require_relative 'chronic/repeaters/repeater_quarter'
require_relative 'chronic/repeaters/repeater_quarter_name'
require_relative 'chronic/repeaters/repeater_season'
require_relative 'chronic/repeaters/repeater_season_name'
require_relative 'chronic/repeaters/repeater_month'
require_relative 'chronic/repeaters/repeater_month_name'
require_relative 'chronic/repeaters/repeater_fortnight'
require_relative 'chronic/repeaters/repeater_week'
require_relative 'chronic/repeaters/repeater_weekend'
require_relative 'chronic/repeaters/repeater_weekday'
require_relative 'chronic/repeaters/repeater_day'
require_relative 'chronic/repeaters/repeater_day_name'
require_relative 'chronic/repeaters/repeater_day_portion'
require_relative 'chronic/repeaters/repeater_hour'
require_relative 'chronic/repeaters/repeater_minute'
require_relative 'chronic/repeaters/repeater_second'
require_relative 'chronic/repeaters/repeater_time'

# Parse natural language dates and times into Time or Chronic::Span objects.
#
# Examples:
#
#   require 'chronic'
#
#   Time.now   #=> Sun Aug 27 23:18:25 PDT 2006
#
#   Chronic.parse('tomorrow')
#     #=> Mon Aug 28 12:00:00 PDT 2006
#
#   Chronic.parse('monday', :context => :past)
#     #=> Mon Aug 21 12:00:00 PDT 2006
module Chronic

  class << self

    # Returns true when debug mode is enabled.
    attr_accessor :debug

    # Examples:
    #
    #   require 'chronic'
    #   require 'active_support/time'
    #
    #   Time.zone = 'UTC'
    #   Chronic.time_class = Time.zone
    #   Chronic.parse('June 15 2006 at 5:54 AM')
    #     # => Thu, 15 Jun 2006 05:45:00 UTC +00:00
    #
    # Returns The Time class Chronic uses internally.
    attr_accessor :time_class
  end

  self.debug = false
  self.time_class = ::Time


  # Parses a string containing a natural language date or time.
  #
  # If the parser can find a date or time, either a Time or Chronic::Span
  # will be returned (depending on the value of `:guess`). If no
  # date or time can be found, `nil` will be returned.
  #
  # text - The String text to parse.
  # opts - An optional Hash of configuration options passed to Parser::new.
  def self.parse(text, options = {})
    Parser.new(options).parse(text)
  end

  # Construct a new time object determining possible month overflows
  # and leap years.
  #
  # year   - Integer year.
  # month  - Integer month.
  # day    - Integer day.
  # hour   - Integer hour.
  # minute - Integer minute.
  # second - Integer second.
  #
  # Returns a new Time object constructed from these params.
  def self.construct(year, month = 1, day = 1, hour = 0, minute = 0, second = 0, offset = nil)
    if second >= 60
      minute += second / 60
      second = second % 60
    end

    if minute >= 60
      hour += minute / 60
      minute = minute % 60
    end

    if hour >= 24
      day += hour / 24
      hour = hour % 24
    end

    # determine if there is a day overflow. this is complicated by our crappy calendar
    # system (non-constant number of days per month)
    day <= 56 || raise('day must be no more than 56 (makes month resolution easier)')
    if day > 28 # no month ever has fewer than 28 days, so only do this if necessary
      days_this_month = ::Date.leap?(year) ? Date::MONTH_DAYS_LEAP[month] : Date::MONTH_DAYS[month]
      if day > days_this_month
        month += day / days_this_month
        day = day % days_this_month
      end
    end

    if month > 12
      if month % 12 == 0
        year += (month - 12) / 12
        month = 12
      else
        year += month / 12
        month = month % 12
      end
    end
    if Chronic.time_class.name == 'Date'
      Chronic.time_class.new(year, month, day)
    elsif not Chronic.time_class.respond_to?(:new) or (RUBY_VERSION.to_f < 1.9 and Chronic.time_class.name == 'Time')
      Chronic.time_class.local(year, month, day, hour, minute, second)
    else
      offset = Time::normalize_offset(offset) if Chronic.time_class.name == 'DateTime'
      Chronic.time_class.new(year, month, day, hour, minute, second, offset)
    end
  end

end
