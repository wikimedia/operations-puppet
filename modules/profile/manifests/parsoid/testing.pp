# Parsoid testing rig: repo clone, nginx site, mysql client, firewall holes
class profile::parsoid::testing (
    Stdlib::Port $parsoid_port = lookup('parsoid::testing::parsoid_port'),
    Stdlib::Httpurl $default_api_proxy_uri = lookup('parsoid::testing::default_api_proxy_uri'),
) {

    git::clone { 'mediawiki/services/parsoid':
        branch    => 'master',
        owner     => 'root',
        group     => 'wikidev',
        directory => '/srv/parsoid-testing',
        shared    => true,
    }

    # mysql client and configuration to provide command line access to
    # parsoid testing database
    include passwords::testreduce::mysql
    $parsoid_cli_password = $passwords::testreduce::mysql::mysql_client_pass
    $parsoid_test_db_host = 'localhost'

    if debian::codename::le('stretch') {
        package { [
            'mysql-client',
            ]: ensure => present,
        }

        file { '/etc/my.cnf':
            content => template('role/mariadb/mysqld_config/parsoid_testing.my.cnf'),
            owner   => 'root',
            group   => 'parsoid-test-roots',
            mode    => '0440',
        }
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'php7.2-fpm': }
    profile::auto_restarts::service { 'nginx': }

    nginx::site { 'nginx-parsoid-testing':
        content => template('profile/parsoid/parsoid-testing.nginx.conf.erb'),
        notify  => Service['nginx'],
    }

    ferm::service { 'nginx-parsoid-testing':
        proto  => 'tcp',
        port   => 8001,
        srange => '$PRODUCTION_NETWORKS',
    }

    # Presented by the @remote links shown on parsoid-rt-tests.wikimedia.org
    ferm::service { 'parsoid-testing':
        proto  => 'tcp',
        port   => 8142,
        srange => '$PRODUCTION_NETWORKS',
    }
}
