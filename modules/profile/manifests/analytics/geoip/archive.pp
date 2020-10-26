# == Class profile::analytics::geoip::archive
#
# Sets up a cron job that grabs the latest version of the MaxMind database
# and pushes its contents to hdfs.
#
class profile::analytics::geoip::archive(
    Boolean $use_kerberos        = lookup('profile::analytics::geoip::archive::use_kerberos'),
    Wmflib::Ensure $ensure       = lookup('profile::analytics::geoip::archive::ensure', { 'default_value' => 'present' }),
) {

    $archive_script = '/usr/local/bin/geoip_archive.sh'
    $maxmind_db_source_dir = '/usr/share/GeoIP'
    $hdfs_archive_dir = '/wmf/data/archive/geoip'

    file { $archive_script:
        ensure  => $ensure,
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
