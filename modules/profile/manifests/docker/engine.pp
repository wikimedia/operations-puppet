# == Profile docker::engine
#
# Installs docker, along with setting up the volume group needed for the
# devicemapper storage driver to work.
# to work
class profile::docker::engine {

    # Optional parameters
    $docker_settings = hiera('profile::docker::engine::settings', {})
    # Version to install; the default is not to pick one.
    $docker_version = hiera('profile::docker::engine::version', 'present')
    $apt_proxy = hiera('profile::docker::engine::proxy', undef)
    $service_ensure = hiera('profile::docker::engine::service', 'running')

    # Install docker
    class { 'docker':
        version => $docker_version,
        proxy   => $apt_proxy,
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
