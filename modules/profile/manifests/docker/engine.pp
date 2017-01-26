# == Profile docker::engine
#
# Installs docker, along with setting up the volume group needed for the
# devicemapper storage driver to work.
# to work
class profile::docker::engine(
    # We want to get settings across the hierarchy, some per host, some fleet
    # wide. So use hiera_hash to merge keys across the hierarchy
    $settings = hiera_hash('profile::docker::engine::settings'),
    # Version to install; the default is not to pick one.
    $version = hiera('profile::docker::engine::version'),
    # Set to false if we don't want to declare the docker service here
    # We want this to be on if we want to use a different docker systemd service (with flannel support, for eg.)
    $declare_service = hiera('profile::docker::engine::declare_service')
) {

    # Install docker
    class { '::docker':
        version => $version,
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
        settings => merge($settings, $docker_storage_options),
    }

    # Enable memory cgroup
    grub::bootparam { 'cgroup_enable':
        value => 'memory',
    }

    grub::bootparam { 'swapaccount':
        value => '1',
    }

    if $declare_service {
        # Service declaration
        service { 'docker':
            ensure => 'running',
        }
    }
}
