# -*- coding: UTF-8 -*-
#
# == Function: to_milliseconds( string $time_spec )
#
# Convert a unit of time expressed as a string to milliseconds.
#
# === Examples
#
#  to_milliseconds('1s')        # 1000
#  to_milliseconds('1 second')  # 1000
#
module Puppet::Parser::Functions
  newfunction(:to_milliseconds, :type => :rvalue, :arity => 1) do |args|
    time_spec = args.first
    /^([0-9.+e]+)\s*(.*).?$/ =~ time_spec.downcase
    count, unit = $1, $2
    factor = case unit
             when /^n/         then 1.0e-6      # nanoseconds
             when /^u/         then 1.0e-3      # microseconds
             when /^(ms|mil)/  then 1.0         # milliseconds
             when /^s/         then 1.0e3       # seconds
             when /^(m|min)/   then 6.0e4       # minutes
             when /^h/         then 3.6e6       # hours
             when /^d/         then 8.64e7      # days
             when /^w/         then 6.048e8     # weeks
             when /^mo/        then 2.62974e9   # months
             when /^y/         then 3.15569e10  # years
             else fail(ArgumentError, "to_milliseconds(): Invalid time spec #{time_spec.inspect}")
    end
    ms = factor * Float(count)
    ms.to_i == ms ? ms.to_i : ms
  end
end
