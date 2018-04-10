# Set up a cron to archive every version of the MaxMind GeoIP database in a local git repository,
# then backup that repo in a different stat machine.
class geoip::data::archive {
  $root_dir = '/srv/'
  $geoip_dir = "${root_dir}geoip/"
  $archive_dir = "${geoip_dir}archive/"
  $repo_dir = "${archive_dir}MaxMind-database/"
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

  $archive_log_command = "/bin/echo -e \"\$(/bin/date): archiving out of date MaxMind data to git repository in ${archive_dir}\""
  $archive_command = "${archive_dir}archive.sh"
  # $backup_host = 'stat1006.eqiad.wmnet'
  # $backup_command = "/usr/bin/rsync -az /srv/geoip/ ${backup_host}::srv/geoip" # the remote address should probably be in a config somewhere else

  cron { 'archivemaxmind':
    ensure      => present,
    command     => "${archive_log_command} && ${archive_command}",
    environment => 'MAILTO=analytics-alerts@wikimedia.org',
    user        => root,
    hour        => 5,
    minute      => 30
  }
}