# == Class geoip::data::lite
# Installs Maxmind GeoLite database files by downloading them from Maxmind with
# a wget wrapper script. This also installs a cron job to do this weekly.
#
# == Parameters
# $data_directory - Where the data files should live.
# $environment    - The environment parameter to pass to exec and cron for the
#                   geoliteupdate download command. default: undef

class geoip::data::lite(
  $data_directory = '/usr/share/GeoIP',
  $environment    = undef)
{
  if ! defined(File[$data_directory]) {
    file { $data_directory:
      ensure => directory,
    }
  }

  file { '/usr/local/bin/geoliteupdate':
    ensure => present,
    mode   => '0555',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/geoip/geoliteupdate',
  }

  $geoliteupdate_command = "/usr/local/bin/geoliteupdate ${data_directory}"

  # run once on the first instantiation of this class
  exec { 'geoliteupdate':
    command     => $geoliteupdate_command,
    refreshonly => true,
    subscribe   => File['/usr/local/bin/geoliteupdate'],
    require     => File[$data_directory],
  }

  # Set up a cron to run geoliteupdate weekly.
  cron { 'geoliteupdate':
    ensure      => present,
    command     => "${geoliteupdate_command} &> /dev/null",
    user        => 'root',
    weekday     => 0,
    hour        => 3,
    minute      => 30,
    require     => File[$data_directory],
  }

  # if $environment was passed in,
  # set it on the geoliteupdate commands
  if ($environment != undef) {
    Exec['geoliteupdate'] { environment => $environment }
    Cron['geoliteupdate'] { environment => $environment }
  }
}
