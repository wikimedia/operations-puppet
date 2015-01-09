# coredb_mysql required packages
class coredb_mysql::packages {
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        file { '/etc/apt/sources.list.d/wikimedia-mariadb.list':
            group  => 'root',
            mode   => '0444',
            owner  => 'root',
            source => 'puppet:///modules/coredb_mysql/wikimedia-mariadb.list',
        }

        exec { 'update_mysql_apt':
            subscribe   => File['/etc/apt/sources.list.d/wikimedia-mariadb.list'],
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
        }

        package { [
            'libmariadbclient18',
            'mariadb-client-5.5',
            'mariadb-server-5.5',
            'mariadb-server-core-5.5',
        ]:
            ensure  => present,
            require => File['/etc/apt/sources.list.d/wikimedia-mariadb.list'],
        }
    } else {
        fail("coredb_mysql is deprecated and does not support ${::lsbdistid}. Please use the 'mariadb' module")
    }

    package { [
        'libaio1',
        'lvm2',
        'percona-toolkit',
        'percona-xtrabackup',
    ]:
        ensure => latest,
    }
}
