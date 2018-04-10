# == Class geoip::data::archive
#

# Sets up a cron job that grabs the latest version of the MaxMind database, puts it
# in a timestamped directory in /srv/geoip/archive, and pushes its contents to hdfs.

class geoip::data::archive(
    $maxmind_db_source_dir = '/usr/share/GeoIP',
    $working_dir = '/srv/GeoIP'
) {
    $archive_dir = "${working_dir}/archive"

    # Puppet assigns 755 permissions to files and dirs, so the script can be ran
    # manually without sudo.

    file { $working_dir:
        ensure => directory,
        owner  => 'root',
        # group  => 'wikidev',
    }
    file { $archive_dir:
        ensure => directory,
        owner  => 'root',
        # group  => 'wikidev',
    }

    file { "${working_dir}/archive.sh":
        ensure  => file,
        owner   => 'root',
        # group   => 'wikidev',
        content => template('geoip/archive.sh.erb')
    }

    $archive_command = "/bin/sh ${working_dir}/archive.sh > /dev/null"

    cron { 'archive-maxmind-geoip-database':
        ensure      => present,
        command     => $archive_command,
        environment => 'MAILTO=analytics-alerts@wikimedia.org',
        user        => root,
        hour        => 5,
        minute      => 30
    }
}