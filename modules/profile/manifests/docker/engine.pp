# SPDX-License-Identifier: Apache-2.0
# == Profile docker::engine
#
# Installs docker

class profile::docker::engine (
    # We want to get settings across the hierarchy, some per host, some fleet
    # wide. So use hash merge behavior to merge keys across the hierarchy
    Hash $settings = lookup('profile::docker::engine::settings', { 'default_value' => {} }),
    # Override the default docker engine package name, defaults to the current name for the docker package.
    Optional[String] $packagename = lookup('profile::docker::engine::packagename', { 'default_value' => 'docker.io' }),
    # Set to false if we don't want to declare the docker service here
    # We want this to be on if we want to use a different docker systemd service (with flannel support, for eg.)
    Boolean $declare_service = lookup('profile::docker::engine::declare_service', { 'default_value' => true }),
) {
    if debian::codename::le('buster') {
        # See https://docs.docker.com/engine/install/linux-postinstall/#your-kernel-does-not-support-cgroup-swap-limit-capabilities
        # This seems not needed on Bullseye since Docker is provided.
        require profile::base::memory_cgroup
    }

    # Docker config
    # We enforce overlay2 storage driver as default and ensure docker does not fall back
    # to devicemapper in case of problems (e.g. unable to load the overlay module).
    $storage_driver = 'storage-driver' in $settings ? {
        true  => $settings['storage-driver'],
        false => 'overlay2',
    }
    if ( $storage_driver == 'overlay2' and defined(Class['profile::base']) and $profile::base::overlayfs == false) {
        fail('Please ensure you declare profile::base::overlayfs: true in hiera.')
    }

    class { 'docker::configuration':
        settings => merge($settings, { 'storage-driver' => $storage_driver }),
    }

    # Install docker, we should remove the "version" parameter when everything
    # is using Buster/Docker as packaged by Debian.
    class { 'docker':
        package_name => $packagename,
    }

    if $declare_service {
        # Service declaration
        service { 'docker':
            ensure => 'running',
        }
    }

    # Check if dragonfly::dfdaemon is configured for this host
    if defined(Class['profile::dragonfly::dfdaemon']) {
        $dragonfly_enabled = $profile::dragonfly::dfdaemon::ensure ? {
        'absent'  => false,
        default   => true,
        }
    } else {
        $dragonfly_enabled = false
    }
    if $dragonfly_enabled {
        # Configure the docker daemon to use the local dfdaemon as https_proxy
        $proxy_host = '127.0.0.1:65001'
        systemd::unit { 'docker':
            ensure   => present,
            override => true,
            restart  => true,
            content  => "[Service]\nEnvironment=\"HTTPS_PROXY=https://${proxy_host}\"",
        }
    }
}
