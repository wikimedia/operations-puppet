class docker_registry_ha (
    String $swift_user,
    String $swift_password,
    Stdlib::Httpurl $swift_url,
    String $swift_container,
    Stdlib::Host $redis_host,
    Stdlib::Port::Unprivileged $redis_port,
    String $redis_passwd,
    String $registry_shared_secret
){



    # the required docker-registry version (2.7.0) is not available for jessie
    # so you cannot install this module on jessie.
    requires_os('debian > jessie')

    # this could be removed when buster or next debian includes a 2.7+ version
    apt::pin { 'strech_wikimedia_docker_registry_27':
        package  => 'docker-registry',
        pin      => 'version 2.7.0~rc0~wmf1-1',
        priority => '1002',
    }

    package {'docker-registry':
        ensure => present,
    }

    file { '/etc/docker/registry/config.yml':
        content => template('docker_registry_ha/registry-ha-config.yaml.erb'),
        owner   => 'docker-registry',
        group   => 'docker-registry',
        mode    => '0440',
        notify  => Service['docker-registry'],
    }

    service { 'docker-registry':
        ensure  => running,
        require => File[
            '/etc/docker/registry/config.yml'
        ],
    }
}
