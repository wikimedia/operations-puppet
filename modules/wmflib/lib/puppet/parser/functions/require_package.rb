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
    Puppet::Parser::Functions.function :create_resources
    args.flatten.each do |package_name|
      # Puppet class names are alphanumeric + underscore
      # 'g++' package would yield: 'packages::g__'
      class_name = 'packages::' + package_name.tr('-+', '_')

      # Create host class

      host = compiler.topscope.find_hostclass(class_name)
      unless host
        host = Puppet::Resource::Type.new(:hostclass, class_name)
        known_resource_types.add_hostclass(host)
      end

      # Create class scope

      cls = Puppet::Parser::Resource.new(
          'class', class_name, :scope => compiler.topscope)
      catalog.add_resource(cls) rescue nil
      host.evaluate_code(cls) rescue nil

      # Create package resource

      begin
        host_scope = compiler.topscope.class_scope(host)
        host_scope.function_create_resources(
          ['package', { package_name => { :ensure => :present } }])
      rescue Puppet::Resource::Catalog::DuplicateResourceError
      end

      # Declare dependency

      send Puppet::Parser::Functions.function(:require), [class_name]
    end
  end
end
