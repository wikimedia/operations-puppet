# == Class geoip::data::archive
#
#
# Sets up a cron job that grabs the latest version of the MaxMind database, puts it
# in a timestamped directory in /srv/geoip/archive, and pushes its contents to hdfs.
#
class geoip::data::archive(
    $maxmind_db_source_dir = '/usr/share/GeoIP',
    $hdfs_archive_dir = '/wmf/data/archive/geoip',
    $archive_dir = "${maxmind_db_source_dir}/archive",
    $use_kerberos = false,
) {
    # Puppet assigns 755 permissions to files and dirs, so the script can be ran
    # manually without sudo.
    file { $archive_dir:
        ensure  => directory,
        owner   => 'analytics',
        group   => 'wikidev',
        require => User['analytics'],
    }

    $archive_script = '/usr/local/bin/geoip_archive.sh'

    file { $archive_script:
        ensure  => file,
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0555',
        content => file('geoip/archive.sh')
    }

    $archive_command = "${archive_script} ${maxmind_db_source_dir} ${archive_dir} ${hdfs_archive_dir}"

    kerberos::systemd_timer { 'archive-maxmind-geoip-database':
        description               => 'Archives Maxmind GeoIP files',
        command                   => $archive_command,
        interval                  => 'Tue *-*-* 05:30:00',
        user                      => 'analytics',
        monitoring_contact_groups => 'analytics',
        logging_enabled           => false,
        use_kerberos              => $use_kerberos,
        require                   => [File[$archive_script], User['analytics']],
    }
}
