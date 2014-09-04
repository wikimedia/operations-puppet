# == Function: require_package
#
# Declare a package as a dependency for the current scope.
#
# === Examples
#
#  require_package('python-redis')
#
module Puppet::Parser::Functions
  newfunction(
    :require_package,
    :arity => 1,
    :doc   => <<-END
      Declare a package dependency for the current scope.

      Example: require_package('python-redis')

    END
  ) do |args|
    package_name = args.first

    unless package_name.is_a?(String)
      fail(ArgumentError, 'require_package() takes a string argument')
    end

    Puppet::Parser::Functions.function(:create_resources)
    Puppet::Parser::Functions.function(:require)

    klass_name = 'packages::' + package_name.tr('-', '_')
    resource_params = { package_name => { :ensure => :present } }

    host = Puppet::Resource::Type.new(:hostclass, klass_name)
    known_resource_types.add_hostclass(host)

    klass = host.ensure_in_catalog(compiler.topscope)
    unless klass.evaluated?
      host.evaluate_code(klass)
      klass_scope = compiler.topscope.class_scope(host)
      klass_scope.function_create_resources ['package', resource_params]
    end

    function_require [klass_name]
  end
end
