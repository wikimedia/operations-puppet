# == Function: requires_realm( string $realm, [ string $message ] )
#
# Validate that the host realm is equal to some value.
# Abort catalog compilation if it is not.
#
# === Examples
#
#  # Fail unless running in Labs:
#  requires_realm('labs')
#
module Puppet::Parser::Functions
  newfunction(:requires_realm, :arity => 1) do |args|
    realm, message = args
    fail(ArgumentError, 'requires_realm(): string argument required') unless realm.is_a?(String)
    fail(Puppet::ParseError, message || "Realm '#{realm}' required.") unless realm == lookupvar('realm')
  end
end
