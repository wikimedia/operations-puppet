# == Class geoip::data::puppet
# Installs GeoIP database files from puppetmaster.
#
# == Parameters
# $source         - A valid puppet source directory.
# $data_directory - Where the data files should live.
#
class geoip::data::puppet(
  # lint:ignore:puppet_url_without_modules
  $source = 'puppet:///volatile/GeoIP',
  # lint:endignore
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
