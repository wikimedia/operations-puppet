# == Class geoip::data::archive
#

# Sets up a cron to archive every version of the MaxMind GeoIP database in a
# local git repository.

class geoip::data::archive {
  $root_dir = '/srv'
  $geoip_dir = "${root_dir}/geoip"
  $archive_dir = "${geoip_dir}/archive"
  $repo_dir = "${archive_dir}/MaxMind"
  $archive_tree = [$root_dir, $geoip_dir, $archive_dir, $repo_dir]

  if ! defined(File[$repo_dir]) {
    file { $archive_tree:
      ensure => directory,
    }
  }

  $maxmind_dir = '/usr/share/GeoIP'
  file { "${archive_dir}/archive.sh":
    ensure  => file,
    owner   => 'root',
    group   => 'wikidev',
    mode    => '0700',
    content => template('geoip/archive.sh.erb')
  }

  $archive_command = "${archive_dir}archive.sh"

  cron { 'archive-maxmind-geoip-database':
    ensure      => present,
    command     => "${archive_command}",
    environment => 'MAILTO=analytics-alerts@wikimedia.org',
    user        => root,
    hour        => 5,
    minute      => 30
  }
}