# == Class docker_pusher
#
# Installs small push script used by CI
class docker_pusher {
    file { '/etc/docker-pusher':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
    }

    file { '/etc/docker-pusher/config.yaml':
        ensure    => 'present',
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        content   => secret('docker-pusher/config.yaml'),
        show_diff => false,
    }

    file { '/usr/local/bin/docker-pusher':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
        source => 'puppet:///modules/docker_pusher/docker_pusher.py',
    }
}

