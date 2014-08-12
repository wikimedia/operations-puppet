# == Function: validate_ensure
#
# validate_ensure($ensure): throw an error if the $ensure argument
# is not 'present' or 'absent'.
#
module Puppet::Parser::Functions
  newfunction(
    :validate_ensure,
    :arity => 1,
    :doc   => 'Throw an error if the argument is not "present" or "absent".'
  ) do |args|
    unless ['present', 'absent'].include? args.first
      raise Puppet::ParseError, "$ensure must be \"present\" or \"absent\" (got: #{args.first.inspect})."
    end
  end
end
