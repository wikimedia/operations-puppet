# ensure_directory(): converts converts 'true'/'present' to 'directory'
# and 'false'/'absent' to 'absent'.
module Puppet::Parser::Functions
  newfunction(
    :ensure_directory,
    :type => :rvalue,
    :doc  => "Converts 'true'/'present' to 'directory' and 'false'/'absent' to 'absent'"
  ) do |args|
    case args[0]
      when 'present', 'true', true then 'directory'
      when 'absent', 'false', false then args[0]
      else raise Puppet::ParseError, 'ensure_directory(): invalid argument'
    end
  end
end

# vim: set ts=2 sw=2 et :
