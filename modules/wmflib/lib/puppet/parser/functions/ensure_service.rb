# ensure_service(): converts converts 'true'/'present' to 'running'
# and 'false'/'absent' to 'absent'.
module Puppet::Parser::Functions
  newfunction(
    :ensure_service,
    :type => :rvalue,
    :doc  => "Converts 'true'/'present' to 'running' and 'false'/'absent' to 'absent'"
  ) do |args|
    case args[0]
      when 'running', 'present', 'true', true then 'running'
      when 'stopped', 'absent', 'false', false then args[0]
      else raise Puppet::ParseError, 'ensure_service(): invalid argument'
    end
  end
end

# vim: set ts=2 sw=2 et :
