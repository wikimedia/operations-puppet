# == Class geoip::data::package
#
# Installs GeoIP .dat files from the Ubuntu package,
# rather than from puppet or maxmind.
class geoip::data::package inherits geoip::data {
  package { 'geoip-database':
    ensure => installed,
  }
}