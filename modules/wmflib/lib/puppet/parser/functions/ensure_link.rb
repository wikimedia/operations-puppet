# ensure_link(): converts converts 'true'/'present' to 'link'
# and 'false'/'absent' to 'absent'.
module Puppet::Parser::Functions
  newfunction(
    :ensure_link,
    :type => :rvalue,
    :doc  => "Converts 'true'/'present' to 'link' and 'false'/'absent' to 'absent'"
  ) do |args|
    case args[0]
      when 'present', 'true', true then 'link'
      when 'absent', 'false', false then args[0]
      else raise Puppet::ParseError, 'ensure_link(): invalid argument'
    end
  end
end

# vim: set ts=2 sw=2 et :
