# == Function: validate_ensure( string $ensure )
#
# Throw an error if the $ensure argument is not 'present' or 'absent'.
#
# === Examples
#
#  # Abort compilation if $ensure is invalid
#  validate_ensure($ensure)
#
module Puppet::Parser::Functions
  newfunction(:validate_ensure, :arity => 1) do |args|
    unless %w(present absent).include?(args.first)
      fail(Puppet::ParseError, "$ensure must be \"present\" or \"absent\" (got: #{args.first.inspect}).")
    end
  end
end
