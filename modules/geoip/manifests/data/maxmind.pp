# == Class geoip::data::maxmind
# Installs Maxmind GeoIP database files by downloading
# them from Maxmind with the geoipupdate command.
# This also installs a cron job to do this weekly.
#
# == Parameters
# $data_directory - Where the data files should live.  default: $geoip::data::data_directory
# $environment    - The environment parameter to pass to exec and cron for the
#                   geoipupdate download command. default: undef
# $license_key    - MaxMind license key.  Required.
# $user_id        - MaxMind user id.      Required.
# $product_ids    - Array of MaxMind product ids to specify which data files
#                   to download.  default: [106] (Country)
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
# # Include the geoip module (which uses puppet sync for .dat files by default):
# node client_node1 {
#   include geoip
# }
#
# # Or if you only want the .dat files:
# node client_node2 {
#   include geoip::data::puppet
# }
#
class geoip::data::maxmind(
  $data_directory = $geoip::data::data_directory,
  $environment    = undef,
  $license_key    = false,
  $user_id        = false,
  $product_ids    = [106]) inherits geoip::data
{
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

  # Go ahead and exec geoipupdate now, so that
  # we can be sure we have these files if
  # this is the first time puppetmaster is
  # running this class.
  exec { 'geoipupdate':
    command     => $geoipupdate_command,
    refreshonly => true,
    subscribe   => File[$config_file],
    # geoipupdate comes from package geoip-bin
    require     => [Package['geoip-bin'], File[$config_file], File[$data_directory]],
  }

  # Set up a cron to run geoipupdate weekly.
  # This will download .dat files for the specified
  # Maxmind Product IDs.
  cron { 'geoipupdate':
    ensure      => present,
    command     => "/bin/echo -en \"\$(/bin/date):\t\" >> /var/log/geoipupdate.log && ${geoipupdate_command} &>> /var/log/geoipupdate.log",
    user        => root,
    weekday     => 0,
    hour        => 3,
    minute      => 30,
    require     => [Package['geoip-bin'], File[$config_file], File[$data_directory]],
  }

  # if $environment was passed in,
  # set it on the geoipupdate commands
  if ($environment != undef) {
    Exec['geoipupdate'] { environment => $environment }
    Cron['geoipupdate'] { environment => $environment }
  }
}
