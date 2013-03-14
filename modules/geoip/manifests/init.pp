# geoip.pp
#
# Classes to manage installation and update of
# Maxmind GeoIP libraries and data files.
#
# To install geoip packages and ensure that you have up to date .dat files,
# just do:
#
#   include geoip
#
# If you want to manage the installation of the .dat files yourself,
# use the geoip::data class.  The default provider is 'puppet', which means
# the .dat files will be synced from the puppetmaster.  A provider of 'maxmind'
# will download the files directly from maxmind.
#
# NOTE:  The $data_directory parameter (and a few others as well) are
# used multiple times in a few classes.  I have defined them each time
# with a default value so that you CAN use the lower level classes if you
# so choose without having to worry about specifying defaults.  This is
# less DRY than leaving off the default values in the low level classes,
# but meh?  If someone doesn't like this we can remove the default values
# from the low level classes.


# == Class geoip
# Installs Maxmind IP address Geocoding
# packages and database files (via puppet).
#
# This is the only class you need to include if
# you want to be able to use Maxmind GeoIP libs and data.
#
# == Parameters
# $data_directory - Where the GeoIP data files should live.  default:
# /usr/share/GeoIP
#
class geoip($data_directory = '/usr/share/GeoIP') {
  class { 'geoip::packages':                                        }
  class { 'geoip::data':          data_directory => $data_directory }
  class { 'geoip::data::symlink': data_directory => $data_directory }
}
