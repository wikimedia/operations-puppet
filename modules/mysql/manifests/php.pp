# Class: mysql::php
#
# This class installs the php libs for mysql.
#
# Parameters:
#   [*ensure*]   - ensure state for package.
#                  can be specified as version.
#   [*packagee*] - name of package
#
class mysql::php(
  $package_name   = $mysql::params::php_package_name,
  $package_ensure = 'present'
# FIXME - class inheriting from params class
# lint:ignore:class_inherits_from_params_class
) inherits mysql::params {
# lint:endignore

  package { 'php-mysql':
    ensure => $package_ensure,
    name   => $package_name,
  }

}
