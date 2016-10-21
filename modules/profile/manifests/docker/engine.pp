# == Profile docker::engine
#
# Installs docker, along with setting up the volume group needed for the
# devicemapper storage driver to work.
# to work
class profile::docker::engine {
    # Parameters that need to be defined in hiera
    $physical_volumes = hiera('profile::docker::engine::physical_volumes')

    # Optional parameters
    # Volume group to substitute
    $vg_to_remove = hiera('profile::docker::engine::vg_to_remove', undef)
    $docker_settings = hiera('profile::docker::engine::settings', {})
    # Size of the thin pool and the metadata pool.
    $lv_extents = hiera('profile::docker::engine::lv_extents', '95%VG')
    $pool_metadata_size = hiera('profile::docker::engine::lvm_metadata_size', undef)
    # Version to install; the default is not to pick one.
    $docker_version = hiera('profile::docker::engine::version', 'present')
    $apt_proxy = hiera('profile::docker::engine::proxy', undef)
    $service_ensure = hiera('profile::docker::engine::service', 'running')

    # Install docker
    class { 'docker':
        version => $docker_version,
        proxy   => $apt_proxy,
    }

    # Storage
    if $vg_to_remove {
        volume_group { $vg_to_remove:
            ensure           => absent,
            physical_volumes => [],
        }
    }
    $basic_lv_params = {
        extents  => $lv_extents,
        thinpool => true,
        mounted  => false,
        createfs => false,
    }

    $lv_params = $pool_metadata_size ? {
        undef   => $basic_lv_params,
        default => merge($basic_lv_params, {'poolmetadatasize' => $pool_metadata_size}),
    }

    $logical_volumes = {
        'thinpool'     => $lv_params,
    }

    $volume_group = {
        docker => {
            ensure           => present,
            physical_volumes => $physical_volumes,
            logical_volumes  => $logical_volumes,
        }
    }

    class { 'lvm':
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

    $docker_storage_options = {
        'storage-driver' => 'devicemapper',
        'storage-opts'   =>  [
            'dm.thinpooldev=/dev/mapper/docker-thinpool-tpool',
            'dm.use_deferred_removal=true',
            'dm.use_deferred_deletion=true'
        ]
    }


    # Docker config
    class { 'docker::configuration':
        settings => merge($docker_settings, $docker_storage_options),
    }

    # Service declaration
    service { 'docker':
        ensure => $service_ensure,
    }
}
