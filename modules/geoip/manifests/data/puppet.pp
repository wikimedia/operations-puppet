# == Class geoip::data::puppet
# Installs GeoIP database files from puppetmaster.
#
# == Parameters
# $data_directory - Where the data files should live. Default: $geoip::data::data_directory
# $source         - A valid puppet source directory.  Default: puppet:///files/GeoIP
#
class geoip::data::puppet(
  $data_directory = $geoip::data::data_directory,
  $source         = 'puppet:///files/GeoIP') inherits geoip::data
{
  # Recursively copy the $data_directory from $source.
  # (The file resource for $data_directory is defined in geoip::data.)
  File[$data_directory] {
    source  => $source,
    recurse => true,
  }
}
