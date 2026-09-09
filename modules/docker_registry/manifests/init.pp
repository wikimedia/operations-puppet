# SPDX-License-Identifier: Apache-2.0
# Installs docker distribution (the name for the registry software) and some prerequisite packages
# This class doesn't setup a running registry, docker_registry::instance is also required
class docker_registry (
){
    package {'docker-registry':
        ensure => present,
    }

    systemd::sysuser { 'docker-registry':
        shell  => '/bin/bash',
        before => Package['docker-registry'],
    }

    ensure_packages([
        's3cmd',
        'skopeo'
    ])

    # Disable the main service shipped with the package, we will be instantiating our own stuff via systemd::service
    service { 'docker-registry':
        ensure => stopped,
        enable => false,
    }
    systemd::mask { 'docker-registry.service': }
    # Remove the main config files shipped with the package, we want our own, shipped via docker_registry::instance
    file { '/etc/docker/registry/config.yml':
        ensure => absent,
    }
}
