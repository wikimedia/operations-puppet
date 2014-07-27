# ensure_service(): converts true/'present' to 'running'
# and false/'absent' to 'stopped'.
module Puppet::Parser::Functions
  newfunction(
    :ensure_service,
    :type => :rvalue,
    :doc  => "Converts true/'present' to 'running' and false/'absent' to 'stopped'"
  ) do |args|
    case args[0]
      when 'running', 'present', 'true', true then 'running'
      when 'stopped', 'absent', 'false', false then 'stopped'
      else raise Puppet::ParseError, 'ensure_service(): invalid argument'
    end
  end
end
