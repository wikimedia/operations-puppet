# == Function: requires_os( string $version_predicate )
#
# Validate that the host operating system version satisfies a version
# check. Abort catalog compilation if not.
#
# See the documentation for os_version() for supported predicate syntax.
#
# === Examples
#
#  # Fail unless version is exactly Debian Jessie
#  requires_os('debian jessie')
#
#  # Fail unless Ubuntu Trusty or newer or Debian Jessie or newer
#  requires_os('ubuntu >= trusty || debian >= Jessie')
#
module Puppet::Parser::Functions
  newfunction(:requires_os, :arity => 1) do |args|
    Puppet::Parser::Functions.function(:os_version)
    fail(ArgumentError, 'requires_os(): string argument required') unless args.first.is_a?(String)
    fail(Puppet::ParseError, "OS #{args.first} required.") unless function_os_version(args)
  end
end
