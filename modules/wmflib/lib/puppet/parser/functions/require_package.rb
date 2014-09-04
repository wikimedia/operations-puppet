# == Function: require_package
#
# Declare a package as a dependency for the current scope.
#
# === Examples
#
#  require_package('python-redis')
#
module Puppet::Parser::Functions
  newfunction(:require_package, :arity => 1) do |args|
    unless args.first.is_a?(String)
      fail(ArgumentError, 'require_package(): string argument required.')
    end

    package_name = args.first
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
