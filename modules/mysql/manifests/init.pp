# Class: mysql
#
#   This class installs mysql client software.
#
# Parameters:
#   [*client_package_name*]  - The name of the mysql client package.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql (
  $package_name   = $mysql::params::client_package_name,
  $package_ensure = 'present'
# FIXME - class inheriting from params class
# lint:ignore:class_inherits_from_params_class
) inherits mysql::params {
# lint:endignore

  package { 'mysql_client':
    ensure => $package_ensure,
    name   => $package_name,
  }

}
