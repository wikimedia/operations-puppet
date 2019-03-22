# Parsoid roundtrip testing, Parsoid & PHP parser visual diff testing
class profile::parsoid::testing (
    $parsoid_port = hiera('parsoid::testing::parsoid_port'),
    $default_api_proxy_uri = hiera('parsoid::testing::default_api_proxy_uri'),
) {

    class { '::parsoid':
        port       => $parsoid_port,
        deployment => 'git',
        no_workers => 1,
        conf       => template('testreduce/parsoid-rt.config.yaml.erb'),
    }

    base::service_auto_restart { 'parsoid': }

    file { '/usr/local/bin/update_parsoid.sh':
        source => 'puppet:///modules/parsoid/parsoid_testing.update_parsoid.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # mysql client and configuration to provide command line access to
    # parsoid testing database
    include ::passwords::testreduce::mysql
    $parsoid_cli_password = $passwords::testreduce::mysql::mysql_client_pass
    $parsoid_test_db_host = 'm5-master.eqiad.wmnet'

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

    nginx::site { 'nginx-parsoid-testing':
        content => template('parsoid/parsoid-testing.nginx.conf.erb'),
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
