# This role is used by testing services
# Ex: Parsoid roundtrip testing, Parsoid & PHP parser visual diff testing
class role::parsoid::testing {
    system::role { 'role::parsoid::testing':
        description => 'Parsoid server (rt-testing, visual-diffing, etc.)'
    }

    $parsoid_port = hiera('parsoid::testing::parsoid_port')

    class { '::parsoid':
        port          => $parsoid_port,
        settings_file => '/srv/deployment/parsoid/deploy/src/localsettings.js',
        deployment    => 'git',
    }

    file { '/usr/local/bin/update_parsoid.sh':
        source => 'puppet:///modules/parsoid/parsoid_testing.update_parsoid.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Use this parsoid instance for parsoid rt-testing
    file { '/srv/deployment/parsoid/deploy/src/localsettings.js':
        content => template('testreduce/parsoid-rt-client.rttest.localsettings.js.erb'),
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0444',
        before  => Service['parsoid'],
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
}
