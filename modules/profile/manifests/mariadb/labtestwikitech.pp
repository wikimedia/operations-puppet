class profile::mariadb::labtestwikitech(
    $maintenance_hosts = hiera('maintenance_hosts'),
    Array[String] $mysql_root_clients = hiera('mysql_root_clients', []),
){
    include passwords::misc::scripts
    include mariadb::packages_wmf
    include mariadb::service

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/wikitech.my.cnf.erb',
        datadir => '/srv/sqldata',
        basedir => '/opt/wmf-mariadb101',
        tmpdir  => '/srv/tmp',
    }

    # mysql monitoring and administration from root clients/tendril
    $mysql_root_clients_str = join($mysql_root_clients, ' ')
    ferm::service { 'mysql_admin_standard':
        proto  => 'tcp',
        port   => '3306',
        srange => "(${mysql_root_clients_str})",
    }
    ferm::service { 'mysql_admin_alternative':
        proto  => 'tcp',
        port   => '3307',
        srange => "(${mysql_root_clients_str})",
    }

    # mysql from deployment master servers and maintenance hosts (T98682, T109736)
    $maintenance_hosts_str = join($maintenance_hosts, ' ')
    ferm::service { 'mysql_deployment_mwmaint':
        proto  => 'tcp',
        port   => '3306',
        srange => "(\$DEPLOYMENT_HOSTS ${maintenance_hosts_str})",
    }

    service { 'mariadb':
        ensure  => running,
        require => Class['mariadb::packages_wmf', 'mariadb::config'],
    }
}
