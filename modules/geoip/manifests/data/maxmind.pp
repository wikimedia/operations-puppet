# == Class geoip::data::maxmind
# Installs Maxmind GeoIP database files by downloading
# them from Maxmind with the geoipupdate command.
# This also installs a timer job to do this weekly.
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
  Stdlib::Unixpath $data_directory = '/usr/share/GeoIP',
  String $user_id                  = '999999',
  String $license_key              = '000000000000',
  Array $product_ids               = [506],
  Stdlib::Host $ca_server          = $facts['fqdn'],
  Optional[Stdlib::Httpurl] $proxy = undef,
) {
  # Version 3 on buster has different config keys to version 2
  $legacy_format = debian::codename::lt('buster')

  ensure_packages(['geoipupdate'])

  ensure_resource('file', $data_directory, {'ensure' => 'directory'})

  $config_file = '/etc/GeoIP.conf'

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

  # Set up a timer to run geoipupdate daily. This will download .dat files for
  # the specified MaxMind Product IDs.  We expect new data to generally arrive
  # weekly on Tuesdays, but there is no guarantee as to the precise timing in
  # the long term.

  file { '/usr/local/bin/geoipupdate_job_legacy':
      ensure => present,
      mode   => '0555',
      source => 'puppet:///modules/geoip/geoipupdate_job_legacy.sh',
  }

  file { '/etc/geoipupdate_job_legacy':
      ensure  => present,
      mode    => '0555',
      content => template('geoip/geoipupdate_job_legacy.erb'),
  }

  systemd::timer::job { 'geoip_update_legacy':
      ensure             => 'present',
      user               => 'root',
      description        => 'download geoip database from MaxMind',
      command            => '/usr/local/bin/geoipupdate_job_legacy',
      interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 3:30:0'},
      monitoring_enabled => true,
      logging_enabled    => true,
      require            => [
        Package['geoipupdate'],
        File[$config_file],
        File[$data_directory]
      ],
  }

  # logrotate for geoipupdate.log
  logrotate::rule { 'geoipupdate_log_legacy':
    ensure       => present,
    file_glob    => $geoipupdate_log,
    size         => '1M',
    rotate       => 1,
    missing_ok   => true,
    not_if_empty => true,
  }
}
