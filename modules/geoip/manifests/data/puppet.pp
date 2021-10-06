# == Class geoip::data::puppet
# Installs GeoIP database files from puppetmaster.
#
# == Parameters
# $source         - A valid puppet source directory.
# $data_directory - Where the data files should live.
#
class geoip::data::puppet(
  # lint:ignore:puppet_url_without_modules
  String $source = 'puppet:///volatile/GeoIP',
  # lint:endignore
  Stdlib::Unixpath $data_directory = '/usr/share/GeoIP',
  Optional[Boolean] $fetch_ipinfo_dbs = false,
  # lint:ignore:puppet_url_without_modules
  Optional[String] $source_ipinfo = 'puppet:///volatile/GeoIPInfo',
  # lint:endignore
  Optional[Stdlib::Unixpath] $data_directory_ipinfo = '/usr/share/GeoIPInfo',
){

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

  if $fetch_ipinfo_dbs {
      file { $data_directory_ipinfo:
        ensure    =>  directory,
        owner     => 'root',
        group     => 'root',
        mode      => '0644',
        source    => $source_ipinfo,
        recurse   => true,
        backup    => false,
        show_diff => false,
      }
  }
}
