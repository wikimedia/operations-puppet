# == Class geoip::data::symlink
# sets up symlink from /usr/local/share/GeoIP
# to /usr/share/GeoIP.  Some scripts expect GeoIP
# databases to be in this location.
#
# == Parameters
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
#
class geoip::data::symlink($data_directory = '/usr/share/GeoIP') {
  file { '/usr/local/share/GeoIP':
    ensure  => $data_directory,
    require => File[$data_directory],
  }
}
