# == Function: to_seconds( string $time_spec )
#
# Convert a unit of time expressed as a string to seconds.
#
# === Examples
#
#  to_seconds('9000ms')  # 9
#  to_seconds('1hr')     # 3600
#  to_seconds('2 days')  # 172800
#
module Puppet::Parser::Functions
  newfunction(:to_seconds, :type => :rvalue, :arity => 1) do |args|
    s = send(Puppet::Parser::Functions.function(:to_milliseconds), args) / 1000.0
    s.to_i == s ? s.to_i : s
  end
end
