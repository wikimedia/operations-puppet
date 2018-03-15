# This class is used to host the labtestwikitech database
#  locally on labtestweb2xxx.  We're trying to keep
#  random labtest things off of the prod databases.
class role::mariadb::labtestwikitech {

    system::role { 'mariadb::wikitech':
        description => 'Wikitech Database',
    }

    include ::standard
    include ::profile::mariadb::grants::core
    include ::profile::mariadb::monitor
    include passwords::misc::scripts
    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'wikitech',
        mysql_role  => 'standalone',
    }

    include mariadb::packages_wmf
    include mariadb::service

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/wikitech.my.cnf.erb',
        datadir => '/srv/sqldata',
        basedir => '/opt/wmf-mariadb101',
        tmpdir  => '/srv/tmp',
    }

    # mysql monitoring and administration from root clients/tendril
    $mysql_root_clients = join($::network::constants::special_hosts['production']['mysql_root_clients'], ' ')
    ferm::service { 'mysql_admin_standard':
        proto  => 'tcp',
        port   => '3306',
        srange => "(${mysql_root_clients})",
    }
    ferm::service { 'mysql_admin_alternative':
        proto  => 'tcp',
        port   => '3307',
        srange => "(${mysql_root_clients})",
    }

    # mysql from deployment master servers and maintenance hosts (T98682, T109736)
    ferm::service { 'mysql_deployment_terbium':
        proto  => 'tcp',
        port   => '3306',
        srange => '($DEPLOYMENT_HOSTS $MAINTENANCE_HOSTS)',
    }

    service { 'mariadb':
        ensure  => running,
        require => Class['mariadb::packages_wmf', 'mariadb::config'],
    }
}

