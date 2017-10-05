# == Class docker_pusher
#
# Installs small push script used by CI
class docker_pusher(
    $docker_pusher_user,
) {
    file { '/etc/docker-pusher':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
    }

    file { '/etc/docker-pusher/config.json':
        ensure    => 'present',
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        content   => secret('docker-pusher/config.json'),
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

