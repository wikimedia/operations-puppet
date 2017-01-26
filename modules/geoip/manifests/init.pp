# Classes to manage the installation of MaxMind GeoIP libraries and databases
#
# To install the geoip utilities & all of the data you can use
#
#   include geoip
#
# Otherwise, you can manually mix and match any of the geoip::data classes,
# e.g. the easiest option would be to
#
#   include geoip::data::package
#
# which installs the Debian geoip-database package.
#
# == Class geoip
# Convenience class that installs the MaxMind binaries, library & all data
#
class geoip {
  # load the data from the puppetmaster. You need to make sure the puppetmaster
  # includes one or more of the other data classes
  include ::geoip::data::puppet
  include ::geoip::bin
}
