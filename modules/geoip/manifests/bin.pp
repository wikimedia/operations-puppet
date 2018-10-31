# == Class geoip::bin
# Installs the MaxMind binaries & library.
#
class geoip::bin {
  package { ['geoip-bin', 'mmdb-bin']:
    ensure => present,
  }
}
