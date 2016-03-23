# Class: mysql::java
#
# This class installs the mysql-java-connector.
#
# Parameters:
#   [*java_package_name*]  - The name of the mysql java package.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql::java (
  $package_name   = $mysql::params::java_package_name,
  $package_ensure = 'present'
# FIXME - class inheriting from params class
# lint:ignore:class_inherits_from_params_class
) inherits mysql::params {
# lint:endignore

  package { 'mysql-connector-java':
    ensure => $package_ensure,
    name   => $package_name,
  }

}
