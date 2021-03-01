# == Class docker_pusher
#
# Installs small push script used by CI
class docker_pusher(
    String $docker_pusher_user,
    String $docker_registry_user,
    String $docker_registry_password,
) {
    file { '/etc/docker-pusher':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
    }

    $docker_auth = "${docker_registry_user}:${docker_registry_password}";
    file { '/etc/docker-pusher/config.json':
        ensure    => 'present',
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        content   => template('docker_pusher/docker_config.json.erb'),
        show_diff => false,
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

