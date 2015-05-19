# == Class geoip::data::maxmind
# Installs Maxmind GeoIP database files by downloading
# them from Maxmind with the geoipupdate command.
# This also installs a cron job to do this weekly.
#
# == Parameters
# $data_directory - Where the data files should live.
# $license_key    - MaxMind license key.
# $user_id        - MaxMind user id.
# $product_ids    - Array of MaxMind product ids to specify which data files
#                   to download.  default: [506] (GeoLite Country)
# $proxy          - Proxy server to use to fetch files.
# == Example
# You can use this class on your puppetmaster to stick the GeoIP .dat files
# into a fileserver module.  Once the files are there, you can use the
# default geoip::data::puppet class to sync the files from your puppetmaster,
# instead of downloading them from maxmind on all your nodes.
# node puppetmaster {
#   class { 'geoip::data::maxmind':
#      $data_directory => '/etc/puppet/files/GeoIP',
#      ...
#   }
# }
# ...
# node client_node {
#   include geoip::data::puppet
# }
#
class geoip::data::maxmind(
  $data_directory = '/usr/share/GeoIP',
  $user_id        = '999999',
  $license_key    = '000000000000',
  $product_ids    = [506],
  $proxy          = undef
) {
  package { 'geoipupdate':
    ensure => present,
  }

  if ! defined(File[$data_directory]) {
    file { $data_directory:
      ensure => directory,
    }
  }

  $config_file = '/etc/GeoIP.conf'

  validate_string($license_key)
  validate_string($user_id)
  validate_array($product_ids)

  # Install GeoIP.conf with Maxmind user_id, licence_key, and product_ids.
  file { $config_file:
    content => template('geoip/GeoIP.conf.erb'),
  }

  # command to run to update the GeoIP database files
  $geoipupdate_command = "/usr/bin/geoipupdate -f ${config_file} -d ${data_directory}"

  # Go ahead and exec geoipupdate now, so that we can be sure we have these
  # files if this is the first time puppetmaster is running this class.
  exec { 'geoipupdate':
    command     => $geoipupdate_command,
    refreshonly => true,
    subscribe   => File[$config_file],
    require     => [
        Package['geoipupdate'],
        File[$config_file],
        File[$data_directory]
    ],
  }

  $geoipupdate_log = '/var/log/geoipupdate.log'

  # Set up a cron to run geoipupdate weekly. This will download .dat files for
  # the specified MaxMind Product IDs.
  cron { 'geoipupdate':
    ensure  => present,
    command => "/bin/echo -e \"\$(/bin/date): geoipupdate downloading MaxMind .dat files into ${data_directory}\" >> ${geoipupdate_log} && ${geoipupdate_command} &>> /var/log/geoipupdate.log",
    user    => root,
    weekday => 0,
    hour    => 3,
    minute  => 30,
    require => [
        Package['geoipupdate'],
        File[$config_file],
        File[$data_directory]
    ],
  }

  # logrotate for geoipupdate.log
  file { '/etc/logrotate.d/geoipupdate':
    content => template('geoip/geoipupdate.logrotate.erb'),
    require => Cron['geoipupdate'],
  }
}
