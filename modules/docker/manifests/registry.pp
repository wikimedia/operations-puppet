class docker::registry(
    $datapath = '/srv/registry',
){

    require_package('docker-registry')
 
    $config = {
        'version' => '0.1',
        'storage' => {
            'filesystem' => {
                'rootdirectory' => $datapath,
            },
            'cache' => {
                'blobdescriptor' => 'inmemory',
            },
        },
        'http' => {
            'addr' => ':5000',
        },
    }

    file { $datapath:
        ensure => directory,
        mode   => '0775',
        owner  => 'docker-registry',
        group  => 'docker-registry',
    }

    # This is by default 0700 for some reason - nothing sensitive inside
    # that doesn't have additional protection
    file { '/etc/docker':
        ensure => directory,
        mode   => '0555',
    }

    file { '/etc/docker/registry/config.yml':
        content => ordered_yaml($config),
        owner   => 'docker-registry',
        group   => 'docker-registry',
        mode    => '0444',
    }

    service { 'docker-registry':
        ensure  => running,
        require => File[
            '/etc/docker',
            '/etc/docker/registry/config.yml'
        ]
    }
}
