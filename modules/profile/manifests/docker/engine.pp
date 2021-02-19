# == Profile docker::engine
#
# Installs docker, along with setting up the volume group needed for the
# devicemapper storage driver to work.
# to work
class profile::docker::engine(
    # We want to get settings across the hierarchy, some per host, some fleet
    # wide. So use hash merge behavior to merge keys across the hierarchy
    Hash $settings = lookup('profile::docker::engine::settings'),
    # Version to install; the default is not to pick one.
    String $version = lookup('profile::docker::engine::version'),
    String $packagename = lookup('profile::docker::engine::packagename'),
    # Set to false if we don't want to declare the docker service here
    # We want this to be on if we want to use a different docker systemd service (with flannel support, for eg.)
    Boolean $declare_service = lookup('profile::docker::engine::declare_service')
) {

    # On Buster and later we use Docker from Debian
    if debian::codename::lt('buster') {
        apt::repository { 'thirdparty-k8s':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/k8s',
            before     => Class['docker'],
        }
    }

    # Docker config
    # Fetch the storage config from the related driver
    # I know this is horrible
    if defined(Class['profile::docker::storage::thinpool']) {
        $docker_storage_options = $::profile::docker::storage::thinpool::options
    } elsif defined(Class['profile::docker::storage::loopback']) {
        $docker_storage_options = $::profile::docker::storage::loopback::options
    } else {
        $docker_storage_options = $::profile::docker::storage::options
    }

    # We need to import one storage config
    class { 'docker::configuration':
        settings => merge($settings, $docker_storage_options),
    }

    # Install docker, we should remove the "version" parameter when everything
    # is using Buster/Docker as packaged by Debian
    class { 'docker':
        version      => $version,
        package_name => $packagename,
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
