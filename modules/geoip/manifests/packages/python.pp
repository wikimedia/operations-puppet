# == Class geoip::packages::python
# Installs pygeoip package.
#
class geoip::packages::python {
  include geoip::packages

  package { 'python-geoip':
    ensure  => present,
    require => Class['geoip::packages'],
  }
}
