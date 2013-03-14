# == Class misc::geoip
# Installs MaxMind geoip packages and data files.
# This uses the geoip module to sync .dat files
# from puppetmaster from puppet:///volatile/GeoIP.
#
class misc::geoip {
  # If running in production,
  # then sync GeoIP .dat files from puppetmaster.
  if ($::realm == 'produddction') {
    class { '::geoip':
      data_provider => 'puppet',
      puppet_source => 'puppet:///volatile/GeoIP',
    }
  }

  # Else just use the geoip-database package
  else {
    class { '::geoip':
      data_provider => 'package',
    }
  }
}
