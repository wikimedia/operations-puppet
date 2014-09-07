# == Function: require_package / require_packages
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
#  require_packages('redis-server', 'python-redis')
#
#  # Multiple packages as array
#  $deps = [ 'redis-server', 'python-redis' ]
#  require_packages($deps)
#
module Puppet::Parser::Functions
  require_packages = proc do |args|
    Puppet::Parser::Functions.function(:create_resources)
    packages = @compiler.topscope.function_create_resources [ 'package'
      Hash[args.map { |package_name| [package_name, {}] }] ]
    resource.set_parameter(:require, resource[:require].to_a | packages) unless self.is_topscope?
  end

  newfunction :require_package,
              :arity => 1,
              &require_packages

  newfunction :require_packages,
              :arity => -2,
              &require_packages
end
