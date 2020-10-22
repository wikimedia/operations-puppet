# == Class geoip::data::archive
#
#
# Sets up a cron job that grabs the latest version of the MaxMind database
# and pushes its contents to hdfs.
class geoip::data::archive(
    Stdlib::Unixpath $maxmind_db_source_dir = '/usr/share/GeoIP',
    Stdlib::Unixpath $hdfs_archive_dir = '/wmf/data/archive/geoip',
    Boolean $use_kerberos = false,
    Wmflib::Ensure $ensure = 'present',
){

    # This comment is here as a reminder to cleanup the local archive directory on stat1007
    # at /usr/share/GeoIP/archive once T264152 is all done.

    $archive_script = '/usr/local/bin/geoip_archive.sh'

    $archive_script_ensure = $ensure ? {
        'present' => file,
        default   => absent,
    }

    file { $archive_script:
        ensure  => $archive_script_ensure,
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0555',
        content => file('geoip/archive.sh')
    }

    $archive_command = "${archive_script} ${maxmind_db_source_dir} ${hdfs_archive_dir}"

    kerberos::systemd_timer { 'archive-maxmind-geoip-database':
        ensure                    => $ensure,
        description               => 'Archives Maxmind GeoIP files',
        command                   => $archive_command,
        interval                  => 'Tue *-*-* 05:30:00',
        user                      => 'analytics',
        monitoring_contact_groups => 'analytics',
        use_kerberos              => $use_kerberos,
        require                   => [File[$archive_script], User['analytics']],
    }
}
