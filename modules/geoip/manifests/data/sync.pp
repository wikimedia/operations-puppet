# == Class geoip::data::sync
# Installs GeoIP database files from puppetmaster.
#
# == Parameters
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
# $source         - A valid puppet source directory.   default: puppet:///volatile/GeoIP
#
class geoip::data::sync(
  $data_directory = '/usr/share/GeoIP',
  $source         = 'puppet:///volatile/GeoIP'
) {
  # recursively copy the $data_directory from $source.
  file { $data_directory:
    source  => $source,
    recurse => true,
  }
}
