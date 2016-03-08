# This role is used by testing services
# Ex: Parsoid roundtrip testing, Parsoid & PHP parser visual diff testing
class role::parsoid::testing {
    system::role { 'role::parsoid::testing':
        description => 'Parsoid server (rt-testing, visual-diffing, etc.)'
    }

    # Some visual diff node modules reference 'node' which this package provides
    require_package('nodejs-legacy')

    include role::parsoid::common

    group { 'parsoid':
        ensure => present,
        name   => 'parsoid',
        system => true,
    }

    user { 'parsoid':
        gid        => 'parsoid',
        home       => '/var/lib/parsoid',
        managehome => true,
        system     => true,
    }

    # Clone the git repo. Omit ensure => latest since
    # we want to update the repository when necessary.
    # Use mode 0775 so that members of wikidev group
    # can update the code via git pull.
    git::clone { 'mediawiki/services/parsoid/deploy':
        owner              => 'root',
        group              => 'wikidev',
        recurse_submodules => true,
        directory          => '/srv/parsoid',
        mode               => '0775',
        before             => Service['parsoid'],
    }

    file { '/lib/systemd/system/parsoid.service':
        source => 'puppet:///modules/parsoid/parsoid_testing.systemd.service',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        before => Service['parsoid'],
    }

    file { '/var/log/parsoid':
        ensure => directory,
        owner  => 'parsoid',
        group  => 'parsoid',
        mode   => '0775',
        before => Service['parsoid'],
    }

    file { '/usr/local/bin/update_parsoid.sh':
        source => 'puppet:///modules/parsoid/parsoid_testing.update_parsoid.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Use this parsoid instance for parsoid rt-testing
    file { '/srv/parsoid/src/localsettings.js':
        content => template('testreduce/parsoid-rt-client.rttest.localsettings.js.erb'),
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0444',
        before  => Service['parsoid'],
    }

    service { 'parsoid':
        hasstatus  => true,
        hasrestart => true,
        subscribe  => [
            File['/lib/systemd/system/parsoid.service'],
        ],
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
        content => template('mariadb/parsoid_testing.my.cnf'),
        owner   => 'root',
        group   => 'parsoid-test-roots',
        mode    => '0440',
    }

    nginx::site { 'nginx-parsoid-testing':
        source => 'puppet:///modules/parsoid/parsoid-testing.nginx.conf',
        notify => Service['nginx'],
    }
}
