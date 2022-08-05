# @summary
# Installs Maxmind GeoIP database files for the IP Info extension
# by downloading them from Maxmind with the geoipupdate command.
# This also installs a timer/job to do this weekly.
#
# The difference to geoip::data::maxmind is a different license
# and different database product IDs.
# This is a transitional class for T288844.
#
# @param data_directory Where the data files should live.
# @param license_key MaxMind license key.
# @param user_id MaxMind user id.
# @param product_ids Array of MaxMind product ids to specify which data files
#                   to download.  default: [506] (GeoLite Country)
# @param proxy Proxy server to use to fetch files.
# @param ca_server The active CA server
# @example Example
# You can use this class on your puppetmaster to stick the GeoIP .dat files
# into a fileserver module.  Once the files are there, you can use the
# default geoip::data::puppet class to sync the files from your puppetmaster,
# instead of downloading them from maxmind on all your nodes.
# node puppetmaster {
#   class { 'geoip::data::maxmind::ipinfo':
#      $data_directory => '/etc/puppet/files/GeoIPInfo',
#      ...
#   }
# }
# ...
# node client_node {
#   include geoip::data::puppet
# }
#
class geoip::data::maxmind::ipinfo(
  Stdlib::Unixpath $data_directory = '/usr/share/GeoIPInfo',
  String $user_id                  = '999999',
  String $license_key              = '000000000000',
  Array $product_ids               = [506],
  Stdlib::Host $ca_server          = $facts['networking']['fqdn'],
  Optional[Stdlib::Httpurl] $proxy = undef,
) {
  ensure_packages(['geoipupdate'])
  ensure_resource('file', $data_directory, {'ensure' => 'directory'})

  $is_active = $facts['networking']['fqdn'] == $ca_server
  $config_file = '/etc/GeoIPInfo.conf'

  # Install GeoIP.conf with Maxmind user_id, licence_key, and product_ids.
  file { $config_file:
    ensure  => file,
    content => template('geoip/GeoIP.conf.erb'),
  }


  if $is_active {
    $geoipupdate_command = "/usr/bin/geoipupdate -f ${config_file} -d ${data_directory}"
    # Go ahead and exec geoipupdate now, so that we can be sure we have these
    # files if this is the first time puppetmaster is running this class.
    exec { 'geoipupdate-ipinfo':
        command     => $geoipupdate_command,
        refreshonly => true,
        require     => [
            Package['geoipupdate'],
            File[$config_file, $data_directory]
        ],
    }
  } else {
    # Emit a log entry if not on the active server
    $geoipupdate_command = "/usr/bin/printf 'this job only runs on the active ca server: ${ca_server}\\n'"
  }

  # Set up a timer to run geoipupdate daily. This will download .dat files for
  # the specified MaxMind Product IDs.  We expect new data to generally arrive
  # weekly on Tuesdays, but there is no gaurantee as to the precise timing in
  # the long term.
  systemd::timer::job { 'geoip_update':
      ensure      => 'absent',
      user        => 'root',
      description => 'download geoip databases for IP Info from MaxMind',
      command     => $geoipupdate_command,
      interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 4:30:0'},
  }

  systemd::timer::job { 'geoip_update_ipinfo':
      ensure             => 'present',
      user               => 'root',
      description        => 'download geoip databases for the IPInfo extension from MaxMind',
      command            => $geoipupdate_command,
      syslog_identifier  => 'geoip_update_ipinfo',
      interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 4:30:0'},
      monitoring_enabled => false,
      logging_enabled    => true,
      require            => [
          Package['geoipupdate'],
          File[$config_file, $data_directory]
      ],
  }
}
