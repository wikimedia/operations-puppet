# == Class geoip::data::puppet
# Installs GeoIP database files from puppetmaster.
#
# == Parameters
# $source         - A valid puppet source directory.
# $data_directory - Where the data files should live. Default: $geoip::data::data_directory
#
class geoip::data::puppet(
  $source,
  $data_directory = $geoip::data::data_directory,
) inherits geoip::data
{
  # Recursively copy the $data_directory from $source.
  # (The file resource for $data_directory is defined in geoip::data.)
  File[$data_directory] {
    source  => $source,
    recurse => true,
  }
}
