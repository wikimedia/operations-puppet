# == Class geoip::data::download
# Installs Maxmind GeoIP database files by downloading
# them from Maxmind with the geoipupdate command.
# This also installs a cron job to do this weekly.
#
# == Parameters
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
# $config_file    - the config file for the geoipupdate command.  This will be put in place from puppet:///private/geoip/GeoIP.conf.  default: /etc/GeoIP.conf
# $environment    - the environment paramter to pass to exec and cron for the
# geoipupdate download command.  default: ''
#
class geoip::data::download(
  $data_directory = '/usr/share/GeoIP',
  $config_file    = '/etc/GeoIP.conf',
  $environment    = ''
) {
  # Need this to get /usr/bin/geoipupdate installed.
  include geoip::packages

  # Install GeoIP.conf with Maxmind license keys.
  file { $config_file:
    source => 'puppet:///private/geoip/GeoIP.conf'
  }

  # Make sure the volatile GeoIP directory exists.
  # Data files will be downloaded by geoipupdate into
  # this directory.
  file { $data_directory:
    ensure => 'directory',
  }

  # command to run to update the GeoIP database files
  $geoipupdate_command = "/usr/bin/geoipupdate -f ${config_file} -d ${data_directory}"

  # Go ahead and exec geoipupdate now, so that
  # we can be sure we have these files if
  # this is the first time puppetmaster is
  # running this class.
  exec { 'geoipupdate':
    command     => $geoipupdate_command,
    environment => $environment,
    refreshonly => true,
    subscribe   => File[$config_file],
    require     => [Package['geoip-bin'], File[$data_directory]],
  }

  # Set up a cron to run geoipupdate weekly.
  # This will download GeoIP.dat and GeoIPCity.dat
  # into /usr/share/GeoIP.  If there are other
  # Maxmind .dat files you want, then
  # modify GeoIP.conf and add the Maxmind
  # product IDs for those files.
  cron { 'geoipupdate':
    ensure      => present,
    command     => "/bin/echo -en \"\$(/bin/date):\t\" >> /var/log/geoipupdate.log && ${geoipupdate_command} &>> /var/log/geoipupdate.log",
    environment => $environment,
    user        => root,
    weekday     => 0,
    hour        => 3,
    minute      => 30,
    require     => [File[$config_file], Package['geoip-bin'], File[$data_directory]],
  }
}
