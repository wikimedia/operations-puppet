# == Class profile::docker::storage::loopback
#
# Sets up the storage for the devicemanager storage driver when
# a loopback device is used.
#
# Do NOT use for serving production traffic.
#
# === Parameters
#
# [*dm_source*] Source device for the /var/lib/docker directory
#
class profile::docker::storage::loopback(
    $dm_source=hiera('profile::docker::storage::loopback::dm_source', undef)
) {
    $dm_target = '/var/lib/docker'

    Class['profile::docker::storage::loopback'] -> Service['docker']

    # This will be used in profile::docker::engine
    $options = {'storage-driver' => 'devicemapper'}

    file { $dm_target:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }


    unless empty($dm_source) {
        mount { $dm_target:
            ensure  => mounted,
            device  => $dm_source,
            fstype  => 'ext4',
            options => 'defaults',
        }
    }

}
