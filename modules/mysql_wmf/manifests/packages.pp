# mysql.pp

# These classes contain a bunch of stuff that's specific to
# the wmf production DB systems.  If you want to construct
# a general-purpose DB server or client, best look elsewhere.

class mysql_wmf::packages {

    # TODO:  Can we strip out this lucid code?
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') == 0 {
        file { '/etc/apt/sources.list.d/wikimedia-mysql.list':
            owner  => root,
            group  => root,
            mode   => '0444',
            source => 'puppet:///modules/mysql_wmf/wikimedia-mysql.list'
        }
        exec { 'update_mysql_apt':
            subscribe   => File['/etc/apt/sources.list.d/wikimedia-mysql.list'],
            command     => '/usr/bin/apt-get update',
            refreshonly => true;
        }
        package { [ 'mysql-client-5.1', 'mysql-server-core-5.1', 'mysql-server-5.1', 'libmysqlclient16' ]:
            ensure  => '5.1.53-fb3753-wm1',
            require => File['/etc/apt/sources.list.d/wikimedia-mysql.list'];
        }
    }
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        if $::mariadb {
            package { [ 'mariadb-client-5.5', 'mariadb-server-core-5.5', 'mariadb-server-5.5', 'libmariadbclient18' ]:
                ensure => '5.5.28-mariadb-wmf201212041~precise',
            }
        } else {
            package { [ 'mysqlfb-client-5.1', 'mysqlfb-server-core-5.1', 'mysqlfb-server-5.1', 'libmysqlfbclient16' ]:
                ensure => '5.1.53-fb3875-wm1',
            }
        }
    }
    package { ['percona-xtrabackup', 'percona-toolkit', 'libaio1', 'lvm2' ]:
        ensure => latest,
    }
}
