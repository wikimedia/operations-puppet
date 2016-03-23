# Class: mysql::ruby
#
# installs the ruby bindings for mysql
#
# Parameters:
#   [*ensure*]       - ensure state for package.
#                        can be specified as version.
#   [*package_name*] - name of package
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql::ruby (
  $package_name     = $mysql::params::ruby_package_name,
  $package_provider = $mysql::params::ruby_package_provider,
  $package_ensure   = 'present'
# FIXME - class inheriting from params class
# lint:ignore:class_inherits_from_params_class
) inherits mysql::params {
# lint:endignore

  package{ 'ruby_mysql':
    ensure   => $package_ensure,
    name     => $package_name,
    provider => $package_provider,
  }

}
