# == Class geoip::data::package
#
# Installs GeoIP .dat files from the Debian package
class geoip::data::package {
  package { 'geoip-database':
    ensure => installed,
  }
}
