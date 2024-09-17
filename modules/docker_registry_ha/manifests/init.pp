# SPDX-License-Identifier: Apache-2.0
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

    package {'docker-registry':
        ensure => present,
    }

    if debian::codename::ge('bookworm') {
        systemd::sysuser { 'docker-registry':
            shell  => '/bin/bash',
            before => Package['docker-registry'],
        }
        ensure_packages('python3-swiftclient')
    } else {
        user { 'docker-registry':
            ensure => present,
            system => true,
            home   => '/nonexistent',
            shell  => '/bin/bash',
            before => Package['docker-registry'],
        }

        ensure_packages('python-swiftclient')
        apt::pin { 'strech_wikimedia_docker_registry_27':
            package  => 'docker-registry',
            pin      => 'version 2.7.0~rc0~wmf1-1',
            priority => 1002,
        }
    }

    file { '/etc/swift':
        ensure => 'directory',
        owner  => 'root',
        group  => 'docker-registry',
        mode   => '0750',
    }
    $account_file = "/etc/swift/account_${swift_user}.env"
    file { $account_file:
            owner   => 'root',
            group   => 'docker-registry',
            mode    => '0440',
            content => "export ST_AUTH=${swift_url}/auth/v1.0\nexport ST_USER=${swift_user}\nexport ST_KEY=${swift_password}\n"
    }

    file { '/usr/local/bin/registry_ha_swift_container_replication.sh':
        source => 'puppet:///modules/docker_registry_ha/registry_ha_swift_container_replication.sh',
        mode   => '0544',
        owner  => 'docker-registry',
        group  => 'docker-registry',
    }
    exec { 'create_swift_container_replication':
        command => "/usr/local/bin/registry_ha_swift_container_replication.sh -x -a ${account_file} \
                    -r ${swift_replication_configuration} \
                    -k ${swift_replication_key} \
                    -c ${swift_container}",
        unless  => "/usr/local/bin/registry_ha_swift_container_replication.sh -t -a ${account_file} \
                    -c ${swift_container}",
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

    rsyslog::input::file { 'registry-nginx-error':
        path => '/var/log/nginx/error.log',
    }

    rsyslog::input::file { 'registry-nginx-access':
        path => '/var/log/nginx/access.log',
    }
}
