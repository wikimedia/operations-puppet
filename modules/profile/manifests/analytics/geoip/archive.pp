# == Class profile::analytics::geoip::archive
#
# Downloads geoip data (MaxMind database) and archives to HDFS
# snapshots of the database over time.
#
class profile::analytics::geoip::archive(
    String $archive_to_hdfs_host = lookup('profile::analytics::geoip::archive::archive_host'),
    Boolean $use_kerberos        = lookup('profile::analytics::geoip::archive::use_kerberos'),
    Wmflib::Ensure $ensure       = lookup('profile::analytics::geoip::archive::ensure', { 'default_value' => 'present' }),
) {

    # For a moment in transition, stat1007 and an-launcher1002 will both claim to be archive_to_hdfs_host
    # so that the changes can apply to both of them as stat1007 turns the timer off and an-launcher1002
    # turns it on. Once the timer is only running on an-launcher1002, this `if` statement can be removed.
    if $::hostname == $archive_to_hdfs_host {
        # Class to save old versions of the geoip MaxMind database, which are useful
        # for historical geocoding.

        $ensure_geoip_dir = $ensure ? {
            'present' => directory,
            default   => absent,
        }

        if !defined(File['/srv/geoip']) {
            file { '/srv/geoip':
                ensure => $ensure_geoip_dir,
                owner  => 'root',
                group  => 'wikidev',
            }
        }

        class { '::geoip::data::archive':
            use_kerberos => $use_kerberos,
            require      => File['/srv/geoip'],
            ensure       => $ensure,
        }
    }
}
