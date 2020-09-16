# == Class profile::analytics::geoip::archive
#
# Downloads geoip data (MaxMind database) and archives to HDFS
# snapshots of the database over time.
#
class profile::analytics::geoip::archive(
    String $archive_to_hdfs_host = lookup('profile::analytics::geoip::archive::archive_host'),
    Boolean $use_kerberos        = lookup('profile::analytics::geoip::archive::use_kerberos'),
) {

    if $::hostname == $archive_to_hdfs_host {
        # Class to save old versions of the geoip MaxMind database, which are useful
        # for historical geocoding.
        if !defined(File['/srv/geoip']) {
            file { '/srv/geoip':
                ensure => directory,
                owner  => 'root',
                group  => 'wikidev',
            }
        }
        class { '::geoip::data::archive':
            archive_dir  => '/srv/geoip/archive',
            use_kerberos => $use_kerberos,
            require      => File['/srv/geoip'],
        }
    }
}
