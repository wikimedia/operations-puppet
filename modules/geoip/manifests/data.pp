# == Class geoip::data
# Conditionally includes either
# geoip::data::sync or geoip::data::download.
#
# The sync class assumes that the data files are
# available via puppet in puppet:///volatile/GeoIP/
#
# The download class runs geoipupdate to download the
# files from maxmind directly.
#
# Currently, source => 'maxmind' is only used by puppetmaster
# to download the files.  All other nodes get these files
# via the default source => 'puppet'.  You shouldn't have
# to worry about this as a user of GeoIP data anyway.  You
# Should just be includeing geoip to get the data files
# and geoip packages.
#
# == Parameters
# $provider       - either 'puppet' or 'maxmind'.      default: puppet.
# $data_directory - Where the data files should live.  default: /usr/share/GeoIP
# $config_file    - the config file for the geoipupdate command.  This will be put in place from puppet:///private/geoip/GeoIP.conf.  This will not be used if the provider is 'puppet'.  default: /etc/GeoIP.conf
# $source         - puppet file source for data_directory.  This is not used if provider is 'maxmind'. default: puppet:///volatile/GeoIP
# $environment    - the environment paramter to pass to exec and cron for the geoipupdate download command.  This will not be used if the provider is 'puppet'.  default: ''
#
class geoip::data(
  $provider       = 'puppet',
  $data_directory = '/usr/share/GeoIP',
  $config_file    = '/etc/GeoIP.conf',
  $source         = 'puppet:///volatile/GeoIP',
  $environment    = ''
) {

  # if installing data files from puppet, use
  # geoip::data::sync class
  if $provider == 'puppet' {
    class { 'geoip::data::sync':
      data_directory => $data_directory,
      source         => $source,
    }
  }

  # else install the files from the maxmind download
  # by including geoip::data::download
  else {
    class { 'geoip::data::download':
      data_directory => $data_directory,
      config_file    => $config_file,
      environment    => $environment,
    }
  }

}
