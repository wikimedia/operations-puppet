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
    args.each do |package_name|
      class_name = 'packages::' + package_name.tr('-', '_')
      unless compiler.topscope.find_hostclass(class_name)
        host = Puppet::Resource::Type.new(:hostclass, class_name)
        known_resource_types.add_hostclass(host)
        send Puppet::Parser::Functions.function(:create_resources),
             ['package', { package_name => { :ensure => :present } }]
      end
      send Puppet::Parser::Functions.function(:require), [class_name]
    end
  end
end
