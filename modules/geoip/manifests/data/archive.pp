# == Class geoip::data::archive
#

# Sets up a cron job that grabs the latest version of the MaxMind database, puts it
# in a timestamped directory in /srv/geoip/archive, and pushes its contents to hdfs.

class geoip::data::archive(
    $maxmind_db_source_dir = '/usr/share/GeoIP'
) {
    $archive_dir = "${maxmind_db_source_dir}/archive"
    # Puppet assigns 755 permissions to files and dirs, so the script can be ran
    # manually without sudo.
    file { $archive_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
    }

    $archive_script_route = '/usr/local/bin/geoip_archive.sh'

    file { $archive_script_route:
        ensure  => file,
        owner   => 'root',
        group   => 'wikidev',
        content => template('geoip/archive.sh.erb')
    }

    $archive_command = "/bin/sh ${archive_script_route} > /dev/null"

    cron { 'archive-maxmind-geoip-database':
        ensure      => present,
        command     => $archive_command,
        environment => 'MAILTO=analytics-alerts@wikimedia.org',
        user        => root,
        weekday     => 3,
        hour        => 5,
        minute      => 30
    }
}