# == Class profile::geoip
#
# Convenient wrapper to deploy the geoip MaxMind database.
#
class profile::geoip {

    class { 'geoip': }

}
