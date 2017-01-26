# == Class profile::docker::storage
#
# Sets up the storage for the devicemanager docker storage driver
# with thick pools
#
# This should be used on jessie, see:
#
# https://github.com/docker/docker/issues/15629
#
class profile::docker::storage(
    # list of physical volumes to use.
    $physical_volumes = hiera('profile::docker::storage::physical_volumes'),
    # Volume group to substitute.
    $vg_to_remove = hiera('profile::docker::storage::vg_to_remove'),
) {
    # Size of the thin pool and the metadata pool.
    $extents = '95%VG'
    $metadata_size = '5%VG'

    Class['::profile::docker::storage'] -> Service['docker']

    if $vg_to_remove {
        volume_group { $vg_to_remove:
            ensure           => absent,
            physical_volumes => [],
        }
    }

    $main_lv_params = {
        extents  => $extents,
        mounted  => false,
        createfs => false,
    }

    $metadata_lv_params = {
        extents  => $metadata_size,
        mounted  => false,
        createfs => false,
    }

    $logical_volumes = {
        'data'     => $main_lv_params,
        'metadata' => $metadata_lv_params,
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

    # This will be used in profile::docker::engine
    $options = {
        'storage-driver' => 'devicemapper',
        'storage-opts'   =>  [
            'dm.datadev=/dev/mapper/docker-data',
            'dm.metadatadev=/dev/mapper/docker-metadata',
        ],
    }
}
