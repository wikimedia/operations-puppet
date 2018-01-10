# This role is used by testing services
# Ex: Parsoid roundtrip testing, Parsoid & PHP parser visual diff testing
class role::parsoid::testing {
    system::role { 'parsoid::testing':
        description => 'Parsoid server (rt-testing, visual-diffing, etc.)'
    }

    $parsoid_port = hiera('parsoid::testing::parsoid_port')

    class { '::parsoid':
        port          => $parsoid_port,
        deployment    => 'git',
        no_workers    => 1,
        conf          => template('testreduce/parsoid-rt.config.yaml.erb'),
    }

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
