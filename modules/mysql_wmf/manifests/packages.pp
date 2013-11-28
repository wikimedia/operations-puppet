
# These classes contain a bunch of stuff that's specific to
# the wmf production DB systems.  If you want to construct
# a general-purpose DB server or client, best look elsewhere.

class mysql_wmf::packages(
    $mariadb = false,
    ) {

    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        if $mariadb == true {
            file { '/etc/apt/sources.list.d/wikimedia-mariadb.list':
                group  => 'root',
                mode   => '0444',
                owner  => 'root',
                source => 'puppet:///modules/mysql_wmf/wikimedia-mariadb.list',
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
            package { [
                'libmysqlfbclient16',
                'mysqlfb-client-5.1',
                'mysqlfb-server-5.1',
                'mysqlfb-server-core-5.1',
            ]:
                ensure => '5.1.53-fb3875-wm1',
            }
        }
    }

    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') == 0 {
        package { [
            'libmysqlclient16',
            'mysql-client-5.1',
            'mysql-server-5.1',
            'mysql-server-core-5.1',
        ]:
            ensure => '5.1.53-fb3753-wm1',
        }
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
