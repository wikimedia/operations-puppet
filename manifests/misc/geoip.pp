# == Class misc::geoip
# Installs MaxMind geoip packages and data files.
# This uses the geoip module to sync .dat files
# from puppetmaster from puppet:///volatile/GeoIP.
#
# TODO:  How should we move this out of misc/ into another
# location.  This isn't a role, but I don't want to reference $::realm
# in the geoip module itself.  What to do?  hmmm hooo...
#
class misc::geoip {
  # If running in production,
  # then sync GeoIP .dat files from puppetmaster.
  if ($::realm == 'production') {
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
