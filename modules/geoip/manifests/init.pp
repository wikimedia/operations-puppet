# geoip.pp
#
# Classes to manage installation and update of
# Maxmind GeoIP libraries and data files.
#
# To install geoip packages and ensure that you have up to date .dat files,
# just do:
#
#   include geoip
#
# If you want to manage the installation of the .dat files yourself,
# use the geoip::data::puppet or geoip::data::maxmind class.  The default
# data_provider is 'package', which means the .dat files will installed from
# the Ubuntu geoip-database package.
#
# If you want to sync files from your puppetmaster, then use a provider of
# 'puppet'. If you do so, ou should use a provider of 'maxmind' on your puppetmaster
# to ensure that the .dat files are updated weekly and in a place
# that your puppet clients can sync from.  See manifests/data/maxmind.pp
# class documentation for an example.

# == Class geoip
# Installs Maxmind IP address Geocoding
# packages and database files (via puppet).
#
# This is the only class you need to include if
# you want to be able to use Maxmind GeoIP libs and data.
#
# == Parameters
# $data_directory - Where the GeoIP data files should live.  default: /usr/share/GeoIP
# $data_provider  - How the Maxmind data files should be obtained.
#                   'puppet' will sync them from the puppetmaster, and requires that the
#                   $puppet_source parameter is passed with a valid puppet source path.
#                   'maxmind' will download the files using geoipupdate directly from MaxMind.
#                   You must pass your MaxMind $license_key and $user_id, as well as the MaxMind
#                   $product_ids for the data files that you want to download.  default: 'puppet'.
#                   If provider is 'none' or anything else, MaxMind data files will not be installed.
# $puppet_source  - Puppet source path for GeoIP files.  default: 'puppet:///files/GeoIP'.
#                   Only used if $data_provider is 'puppet'.
## The following parameters are only used if $data_provider is 'maxmind'.
# $environment    - Shell environment to pass to exec and cron for geoipupdate command.
# $license_key    - MaxMind license key.
# $user_id        - MaxMind user id.
# $product_ids    - Array of MaxMind product ids to specify which data files to download.  default: [106] (Country)
#
class geoip(
  $data_directory = '/usr/share/GeoIP',
  $data_provider  = 'package',

  $puppet_source  = 'puppet:///files/GeoIP',

  $environment    = undef,
  $license_key    = false,
  $user_id        = false,
  $product_ids    = [106])
{
  package { ['libgeoip1', 'libgeoip-dev', 'geoip-bin']:
    ensure => present;
  }

  # if installing via geoip-database
  if $data_provider == 'package' {
    class { 'geoip::data::package': }
  }

  # if installing data files from puppet, use
  # geoip::data::puppet class
  elsif $data_provider == 'puppet' {
    # recursively copy the $data_directory from $source.
    class { 'geoip::data::puppet':
      data_directory  => $data_directory,
      source          => $puppet_source
    }
  }

  # else install the files by maxmind download
  # by including geoip::data::maxmind
  elsif $data_provider == 'maxmind' {
    class { 'geoip::data::maxmind':
      data_directory => $data_directory,
      environment    => $environment,
      license_key    => $license_key,
      user_id        => $user_id,
      product_ids    => $product_ids,
    }
  }
  # else don't install .dat files at all.
}
