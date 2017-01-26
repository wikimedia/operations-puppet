# == Profile docker::engine
#
# Installs docker, along with setting up the volume group needed for the
# devicemapper storage driver to work.
# to work
class profile::docker::engine {

    # Optional parameters
    # We want to get settings across the hierarchy, some per host, some fleet
    # wide. So use hiera_hash to merge keys across the hierarchy
    $docker_settings = hiera_hash('profile::docker::engine::settings', {})
    # Version to install; the default is not to pick one.
    $docker_version = hiera('profile::docker::engine::version', 'present')
    $service_ensure = hiera('profile::docker::engine::service', 'running')

    # Install docker
    class { '::docker':
        version => $docker_version,
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
    class { '::docker::configuration':
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
