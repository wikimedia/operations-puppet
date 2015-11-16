# == Function: conflicts( string|resource $resource )
#
# Throw an error if a resource is declared.
#
# === Examples
#
#  # Resource name
#  conflicts('::redis::legacy')
#
#  # Resource
#  conflicts(Class['::redis-server'])
#
module Puppet::Parser::Functions
  newfunction(:conflicts, :arity => 1) do |args|
    Puppet::Parser::Functions.function(:defined)
    fail(Puppet::ParseError, "Resource conflicts with #{args.first}.") if function_defined(args)
  end
end
