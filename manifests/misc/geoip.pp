# == Class misc::geoip
# Installs MaxMind geoip packages and data files.
# This uses the geoip module to sync .dat files
# from puppetmaster from puppet:///volatile/GeoIP.
#
class misc::geoip {
  class { '::geoip':
    puppet_source => 'puppet:///volatile/GeoIP',
  }
}
