# == Class geoip::data::archive
#
#
# Sets up a cron job that grabs the latest version of the MaxMind database, puts it
# in a timestamped directory in $archive_dir, and pushes its contents to hdfs.
#
class geoip::data::archive(
    Stdlib::Unixpath $maxmind_db_source_dir = '/usr/share/GeoIP',
    Stdlib::Unixpath $hdfs_archive_dir = '/wmf/data/archive/geoip',
    Stdlib::Unixpath $archive_dir = "${maxmind_db_source_dir}/archive",
    Boolean $use_kerberos = false,
    Boolean $enable_timer = false,
){

    # Puppet assigns 755 permissions to files and dirs, so the script can be ran
    # manually without sudo.
    file { $archive_dir:
        ensure  => directory,
        owner   => 'analytics-privatedata',
        group   => 'analytics-privatedata-users',
        require => [
            User['analytics-privatedata'],
            Group['analytics-privatedata-users']
        ],
    }

    $archive_script = '/usr/local/bin/geoip_archive.sh'

    file { $archive_script:
        ensure  => file,
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0555',
        content => file('geoip/archive.sh')
    }

    $archive_command = "${archive_script} ${maxmind_db_source_dir} ${hdfs_archive_dir}"

    kerberos::systemd_timer { 'archive-maxmind-geoip-database':
        description               => 'Archives Maxmind GeoIP files',
        command                   => $archive_command,
        interval                  => 'Tue *-*-* 05:30:00',
        user                      => 'analytics-privatedata',
        monitoring_contact_groups => 'analytics',
        use_kerberos              => $use_kerberos,
        require                   => [File[$archive_script], User['analytics']],
    }
}
