# == Class geoip::data::archive
#

# Sets up a cron to archive every version of the MaxMind GeoIP database in a
# local git repository.

class geoip::data::archive(
    $maxmind_db_source_dir = '/usr/share/GeoIP',
    $working_dir = '/srv/GeoIP'
) {
    $archive_dir = "${working_dir}/archive"
    $repo_dir = "${archive_dir}/MaxMind"

    # Puppet assigns 755 permissions to files and dirs, so the script can be ran
    # manually without sudo.

    file { $working_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
    }
    file { $archive_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
    }
    file { $repo_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
    }

    file { "${archive_dir}/archive.sh":
        ensure  => file,
        owner   => 'root',
        group   => 'wikidev',
        content => template('geoip/archive.sh.erb')
    }

    $archive_command = "${archive_dir}/archive.sh"

    cron { 'archive-maxmind-geoip-database':
        ensure      => present,
        command     => $archive_command,
        environment => 'MAILTO=analytics-alerts@wikimedia.org',
        user        => root,
        hour        => 5,
        minute      => 30
    }
}