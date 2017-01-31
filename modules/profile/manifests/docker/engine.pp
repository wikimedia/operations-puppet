# == Profile docker::engine
#
# Installs docker, along with setting up the volume group needed for the
# devicemapper storage driver to work.
# to work
class profile::docker::engine(
    # Optional parameters
    # We want to get settings across the hierarchy, some per host, some fleet
    # wide. So use hiera_hash to merge keys across the hierarchy
    $docker_settings = hiera_hash('profile::docker::engine::settings', {}),
    # Version to install; the default is not to pick one.
    $docker_version = hiera('profile::docker::engine::version', 'present'),
    $service_ensure = hiera('profile::docker::engine::service', 'running'),
    # Wether to use the debs from upstream dockerproject
    $use_dockerproject = hiera('profile::docker::engine::use_dockerproject', true),
    # Set to true to use upstream's deb repo directly
    $use_docker_io_repo = hiera('profile::docker::engine::use_docker_io_repo', false)
) {

    # Install docker
    class { 'docker':
        version            => $docker_version,
        use_dockerproject  => $use_dockerproject,
        use_docker_io_repo => $use_docker_io_repo,
    }

    # Docker config
    # Fetch the storage config from the related driver
    # I know this is horrible
    if defined(Class['::profile::docker::storage::thinpool']) {
        $docker_storage_options = $::profile::docker::storage::thinpool::options
    } elsif defined(Class['::profile::docker::storage::loopback']) {
        $docker_storage_options = $::profile::docker::storage::loopback::options

    } else {
        $docker_storage_options = $::profile::docker::storage::options
    }

    # We need to import one storage config
    class { 'docker::configuration':
        settings => merge($docker_settings, $docker_storage_options),
    }

    # Enable memory cgroup
    grub::bootparam { 'cgroup_enable':
        value => 'memory',
    }

    grub::bootparam { 'swapaccount':
        value => '1',
    }

    # Service declaration
    service { 'docker':
        ensure => $service_ensure,
    }
}
