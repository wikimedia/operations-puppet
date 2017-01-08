class docker::engine(
    $version = '1.11.2-0~jessie',
    $declare_service = true,
) {

    package { 'bridge-utils':
        ensure => present,
    }

    apt::repository { 'docker':
        uri        => 'https://apt.dockerproject.org/repo',
        dist       => 'debian-jessie',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/docker/docker.gpg',
    }

    file { '/usr/local/bin/setup-docker':
        source => 'puppet:///modules/docker/setup-docker',
        owner  => 'root',
        group  => 'root',
        mode   => '0554',
    }

    exec { 'setup-docker':
        command => "/usr/local/bin/setup-docker ${version}",
        unless  => '/sbin/vgdisplay docker',
        user    => 'root',
        group   => 'root',
        require => [
            Apt::Repository['docker'],
            File['/usr/local/bin/setup-docker']
        ],
    }

    if $declare_service {
        service { 'docker':
            ensure    => running,
        }
    }
}
