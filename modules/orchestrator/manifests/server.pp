# SPDX-License-Identifier: Apache-2.0
class orchestrator::server (
    Enum['mysql', 'sqlite'] $db_backend,
    String[1] $db_topology_password,
    String[1] $db_topology_username = 'orchestrator',
    Optional[Stdlib::Host] $db_backend_host = undef,
    Optional[String[1]] $db_backend_password = undef,
    Stdlib::Port $db_backend_port = 3306,
    String[1] $db_backend_username = 'orchestrator_srv',
    String[1] $db_backend_database = 'orchestrator',
) {
    if $db_backend == 'mysql' {
        if !$db_backend_host {
            fail("\$db_backend_host must be set if \$db_backend is 'mysql'")
        }
        if !$db_backend_password {
            fail("\$db_backend_password must be set if \$db_backend is 'mysql'")
        }
    } elsif $db_backend == 'sqlite' {
        ensure_packages('sqlite3')
    }

    ensure_packages('orchestrator')

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
        group   => 'orchestrator',
        mode    => '0440',
        content => template('orchestrator/orchestrator_srv.cnf.erb'),
        notify  => Service['orchestrator'],
    }

    file { '/etc/mysql/orchestrator_topo.cnf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'orchestrator',
        mode    => '0440',
        content => template('orchestrator/orchestrator_topo.cnf.erb'),
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
