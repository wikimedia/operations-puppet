class docker::engine(
    $version = '1.11.2-0~jessie',
    $declare_service = true,
    $vg_to_remove = 'vd',
    $physical_volumes = ['/dev/vda4'],
) {
    apt::repository { 'docker':
        uri        => 'https://apt.dockerproject.org/repo',
        dist       => 'debian-jessie',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/docker/docker.gpg',
    }

    volume_group { $vg_to_remove:
        ensure           => absent,
        physical_volumes => [],
    }

    volume_group { 'docker':
        ensure           => present,
        physical_volumes => $physical_volumes,
        require          => Volume_group[$vg_to_remove],
    }

    logical_volume { 'data':
        volume_group => 'docker',
        extents      => '95%VG',
    }

    logical_volume { 'metadata':
        volume_group => 'docker',
        extents      => '5%VG',
    }

    package { 'docker-engine':
        ensure  => $version,
        require => Apt::Repository['docker']
    }

    if $declare_service {
        service { 'docker':
            ensure    => running,
            subscribe => Package['docker-engine'],
        }
    }
}
