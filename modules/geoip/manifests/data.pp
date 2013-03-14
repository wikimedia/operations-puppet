# == Class geoip::data
# Base class for geoip data sources.
# Do not include this class directly.
# Instead, use geoip::data::maxmind or geoip::data::puppet.
#
class geoip::data($data_directory = '/usr/share/GeoIP')
{
  # Make sure the volatile GeoIP directory exists.
  file { $data_directory:
    ensure => 'directory',
  }

  # symlink /usr/local/share/GeoIP
  # to /usr/share/GeoIP.  Some scripts expect GeoIP
  # databases to be in this location.
  file { '/usr/local/share/GeoIP':
    ensure  => link,
    target  => $data_directory,
    require => File[$data_directory],
  }
}
