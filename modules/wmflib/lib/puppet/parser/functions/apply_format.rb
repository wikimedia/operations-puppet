# == Function: apply_format
#
# Apply a format string to each element of an array.
# apply_format(format_string, array)
#
module Puppet::Parser::Functions
  newfunction(
    :apply_format,
    :type  => :rvalue,
    :arity => 2,
    :doc   => 'Apply a format string to each element of an array.',
  ) do |args|
    format, items = args
    unless format.is_a? String
        raise Puppet::ParseError, 'apply_format(): a format string is required'
    end
    [items].flatten.map { |item| format % item }
  end
end
