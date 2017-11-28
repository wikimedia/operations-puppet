# == Class profile::docker::storage::thinpool
#
# Sets up the storage for the devicemanager docker storage driver
# when thinpools can be used.
#
# Do NOT use on debian jessie, see
#
# https://github.com/docker/docker/issues/15629
#
class profile::docker::storage::thinpool {
    # Parameters that need to be defined in hiera
    # list of physical volumes to use. Common to all the storage profiles
    $physical_volumes = hiera('profile::docker::storage::physical_volumes')

    # Optional parameters
    # Volume group to substitute. Common to all the storage profiles
    $vg_to_remove = hiera('profile::docker::storage::vg_to_remove', undef)
    # Size of the thin pool and the metadata pool.
    $extents = hiera('profile::docker::storage::extents', '95%VG')
    $metadata_size = hiera('profile::docker::storage::metadata_size', undef)

    if os_version('debian == jessie') {
        fail('Thin pools cannot be used on Debian jessie.')
    }

    Class['::profile::docker::storage::thinpool'] -> Service['docker']

    if $vg_to_remove {
        volume_group { $vg_to_remove:
            ensure           => absent,
            physical_volumes => [],
        }
    }

    $basic_lv_params = {
        extents  => $extents,
        thinpool => true,
        mounted  => false,
        createfs => false,
    }

    $lv_params = $metadata_size ? {
        undef   => $basic_lv_params,
        default => merge($basic_lv_params, {'poolmetadatasize' => $metadata_size}),
    }

    $logical_volumes = {
        'thinpool'     => $lv_params,
    }

    $volume_group = {
        docker => {
            ensure           => present,
            physical_volumes => $physical_volumes,
            logical_volumes  => $logical_volumes,
        },
    }

    class { '::lvm':
        manage_pkg    => true,
        volume_groups => $volume_group,
    }


    file { '/etc/lvm/profile/':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/lvm/profile/docker-thinpool.profile':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/docker/lvm.profile',
    }

    exec { 'Attach profile to docker thinpool':
        command => '/sbin/lvchange --metadataprofile docker-thinpool docker/thinpool',
        unless  => '/sbin/lvs -o lv_profile docker/thinpool | grep -q docker',
        require => [
            File['/etc/lvm/profile/docker-thinpool.profile'],
            Logical_volume['thinpool']
        ],
    }

    # This will be used in profile::docker::engine
    $options = {
        'storage-driver' => 'devicemapper',
        'storage-opts'   =>  [
            'dm.thinpooldev=/dev/mapper/docker-thinpool-tpool',
            'dm.use_deferred_removal=true',
            'dm.use_deferred_deletion=true',
        ],
    }
}
