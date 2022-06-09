# SPDX-License-Identifier: Apache-2.0
# == Class docker_pusher
#
# Installs small push script used by CI
class docker_pusher(
    String $docker_pusher_user,
    String $docker_registry_user,
    String $docker_registry_password,
) {
    # TODO: actually fetch the registry url from hiera.
    # TODO: currently we declare group ownership 'docker',
    # but don't allow reading from the group, which seems
    # pointless to me.
    docker::credentials {'/etc/docker-pusher/config.json':
        owner             => 'root',
        group             => 'root',
        registry          => 'docker-registry.discovery.wmnet',
        registry_username => $docker_registry_user,
        registry_password => $docker_registry_password,
        allow_group       => false
    }

    file { '/usr/local/bin/docker-pusher':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
        source => 'puppet:///modules/docker_pusher/docker_pusher.sh',
    }

    sudo::user { "sudo ${docker_pusher_user} docker-pusher":
        user       => $docker_pusher_user,
        privileges => [
            'ALL=(root) NOPASSWD: /usr/local/bin/docker-pusher *',
        ]
    }
}

