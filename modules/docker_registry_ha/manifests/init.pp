class docker_registry_ha (
    Stdlib::Httpurl $swift_url,
    String $swift_user,
    String $swift_password,
    Pattern[/\/\/[a-zA-Z_]{3,}\/[a-zA-Z_]{3,}\/AUTH_[a-zA-Z_]+\/[a-z_]{3,}/] $swift_replication_configuration,
    String $swift_container,
    String $swift_replication_key,
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
    require_package('python-swiftclient')

    user { 'docker-registry':
        ensure => present,
        system => true,
        home   => '/nonexistent',
        shell  => '/bin/bash',
        before => Package['docker-registry'],
    }
    $account_file = "/etc/swift/account_${swift_user}.env"
    file { $account_file:
            owner   => 'root',
            group   => 'docker-registry',
            mode    => '0440',
            content => "export ST_AUTH=${swift_url}/auth/v1.0\nexport ST_USER=${swift_user}\nexport ST_KEY=${swift_password}\n"
    }

    exec { 'create_swift_container_replication':
        command => "source ${account_file} && swift post \
                    -t '${swift_replication_configuration}' \
                    -k ${swift_replication_key} ${swift_container}",
        unless  => "source ${account_file} && swift stat ${swift_container}",
        cwd     => '/tmp',
        path    => '/bin:/sbin:/usr/bin:/usr/sbin',
        user    => 'docker-registry'
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
