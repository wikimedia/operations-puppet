# == Function: requires_ubuntu( string $version_predicate )
#
# Validate that the host Ubuntu version satisfies a version
# check. Abort catalog compilation if not.
#
# See the documentation for ubuntu_version() for supported
# predicate syntax.
#
# === Examples
#
#  # Fail unless version is Trusty
#  requires_ubuntu('trusty')
#
#  # Fail unless Trusty or newer
#  requires_ubuntu('> trusty')
#
module Puppet::Parser::Functions
  newfunction(:requires_ubuntu, :arity => 1) do |args|
    Puppet::Parser::Functions.function(:ubuntu_version)
    fail(ArgumentError, 'requires_ubuntu(): string argument required') unless args.first.is_a?(String)
    fail(Puppet::ParseError, "Ubuntu #{args.first} required.") unless function_ubuntu_version(args)
  end
end
