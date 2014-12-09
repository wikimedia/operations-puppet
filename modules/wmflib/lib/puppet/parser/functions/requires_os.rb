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
  newfunction(:requires_os, :arity => -2) do |args|
    clauses = args.join('||')
    Puppet::Parser::Functions.function(:os_version)
    fail(Puppet::ParseError, "OS #{clauses} required.") unless function_os_version(clauses)
  end
end
