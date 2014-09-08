# == Function: require_package( string $package_name [, string $... ] )
#
# Declare one or more packages a dependency for the current scope.
# This is equivalent to declaring and requiring the package resources.
# In other words, it ensures the package(s) are installed before
# evaluating any of the resources in the current scope.
#
# === Examples
#
#  # Single package
#  require_package('python-redis')
#
#  # Multiple packages as arguments
#  require_package('redis-server', 'python-redis')
#
#  # Multiple packages as array
#  $deps = [ 'redis-server', 'python-redis' ]
#  require_package($deps)
#
module Puppet::Parser::Functions
  newfunction(:require_package, :arity => -2) do |args|
    Puppet::Parser::Functions.function(:create_resources)
    packages = @compiler.topscope.function_create_resources [
      'package',
      Hash[args.map { |package_name| [package_name, {}] }]
    ]
    unless self.is_topscope?
      resource.set_parameter(:require, resource[:require].to_a | packages)
    end
  end
end
