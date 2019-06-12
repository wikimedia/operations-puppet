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
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
    }

    $archive_script = '/usr/local/bin/geoip_archive.sh'

    file { $archive_script:
        ensure  => file,
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0555',
        content => file('geoip/archive.sh')
    }

    if $use_kerberos {
        $wrapper = '/usr/local/bin/kerberos-puppet-wrapper hdfs '
    } else {
        $wrapper = ''
    }

    $archive_command = "${wrapper}${archive_script} ${maxmind_db_source_dir} ${archive_dir} ${hdfs_archive_dir}"

    systemd::timer::job { 'archive-maxmind-geoip-database':
        description               => 'Archives Maxmind GeoIP files',
        command                   => $archive_command,
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => 'Tue *-*-* 05:30:00',
        },
        user                      => 'root',
        monitoring_contact_groups => 'analytics',
        logging_enabled           => false,
        require                   => File[$archive_script],
    }
}
