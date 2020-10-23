class orchestrator::server (
    Stdlib::Host $db_backend_host,
    String[1] $db_backend_password,
    Stdlib::Port $db_backend_port = 3306,
    String[1] $db_backend_username = 'orchestrator_srv',
    String[1] $db_backend_database = 'orchestrator',
) {
    apt::package_from_component { 'thirdparty-orchestrator-server':
        component => 'thirdparty/orchestrator',
        packages  => ['orchestrator', 'orchestrator-cli']
    }

    file { '/etc/orchestrator.conf.json':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('orchestrator/orchestrator.conf.json.erb'),
        notify  => Service['orchestrator'],
    }

    file { '/etc/mysql/orchestrator_srv.cnf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('orchestrator/orchestrator_srv.cnf.erb'),
        notify  => Service['orchestrator'],
    }

    service { 'orchestrator':
        ensure  => 'running',
        enable  => true,
        require => [
            Package['orchestrator'],
        ],
    }
}
