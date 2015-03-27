# == Class geoip::data::puppet
# Installs GeoIP database files from puppetmaster.
#
# == Parameters
# $source         - A valid puppet source directory.
# $data_directory - Where the data files should live.
#
class geoip::data::puppet(
  $source = 'puppet:///volatile/GeoIP',
  $data_directory = '/usr/share/GeoIP',
)
{
  # recursively copy the $data_directory from $source.
  file { $data_directory:
    ensure    => directory,
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    source    => $source,
    recurse   => true,
    backup    => false,
    show_diff => false,
  }
}
