# == Class geoip::packages
# Installs GeoIP packages.
#
class geoip::packages {
  package { [ 'libgeoip1', 'libgeoip-dev', 'geoip-bin' ]:
    ensure => present;
  }
}
