class docker::registry(
    $datapath = '/srv/registry',
){

    require_package('docker-registry')

    ## Pretty bad hack, should be using a more generic thing
    class { '::k8s::ssl':
        provide_private => true,
        user            => 'docker-registry',
        group           => 'docker-registry',
        target_basedir  => '/var/lib/docker-registry',
    }

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
        'http'     => {
            'addr' => ':5000',
            'host' => $::fqdn,
            'tls'  => {
                # FIXME: YOU SHOULD FEEL BAD ABOUT HARDCODING
                'certificate' => '/var/lib/docker-registry/ssl/certs/cert.pem',
                'key'         => '/var/lib/docker-registry/ssl/private_keys/server.key'
            },
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
        mode    => '0440',
        notify  => Service['docker-registry'],
    }

    service { 'docker-registry':
        ensure  => running,
        require => File[
            '/etc/docker',
            '/etc/docker/registry/config.yml'
        ]
    }
}
