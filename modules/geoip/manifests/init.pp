# Classes to manage the installation of MaxMind GeoIP libraries and databases
#
# To install the geoip utilities & all of the data you can use
#
#   include geoip
#
# == Class geoip
# Convenience class that installs the MaxMind binaries, library & all data
#
class geoip(
    Optional[Boolean] $load_data_from_puppetserver = true,
    Optional[Boolean] $fetch_ipinfo_dbs = false,
){
  # load the data from the puppetmaster. You need to make sure the puppetmaster
  # includes one or more of the other data classes
    if $load_data_from_puppetserver {
        class { 'geoip::data::puppet':
            fetch_ipinfo_dbs => $fetch_ipinfo_dbs,
        }
    }
  include ::geoip::bin
}
