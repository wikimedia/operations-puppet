# -*- coding: UTF-8 -*-
#
# == Function: to_milliseconds( string $time_spec )
#
# Convert a unit of time expressed as a string to seconds.
#
# === Examples
#
#  to_milliseconds('1s')        # 1000
#  to_milliseconds('1 second')  # 1000
#
module Puppet::Parser::Functions
  newfunction(:to_milliseconds, :type => :rvalue, :arity => 1) do |args|
    time_spec = args.first
    return time_spec if time_spec.is_a?(Numeric)
    if /^([0-9.+e]+)\s*(.*).?$/i =~ time_spec.downcase
      count, unit = Float($1), $2
      ms = count * case unit
      when /^n/           then 1.0e-6      # nanoseconds
      when /^(μ|u)/       then 1.0e-3      # microseconds
      when /^(ms|mil.*)$/ then 1.0         # milliseconds
      when /^(|s.*)$/     then 1.0e3       # seconds
      when /^(m|min.*)$/  then 6.0e4       # minutes
      when /^h/           then 3.6e6       # hours
      when /^d/           then 8.64e7      # days
      when /^w/           then 6.048e8     # weeks
      when /^mo/          then 2.62974e9   # months
      when /^y/           then 3.15569e10  # years
      else fail(ArgumentError, "Invalid time spec #{time_spec.inspect}")
      end
    end
    ms.to_i == ms ? ms.to_i : ms
  end
end
