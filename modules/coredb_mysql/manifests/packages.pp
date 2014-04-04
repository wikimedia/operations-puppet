# coredb_mysql required packages
class coredb_mysql::packages {
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        if $mariadb == true {
            apt::repository { 'wikimedia-mariadb':
                uri        => 'http://apt.wikimedia.org/wikimedia',
                dist       => 'precise-wikimedia',
                components => 'mariadb',
            }

            package { [
                'libmariadbclient18',
                'mariadb-client-5.5',
                'mariadb-server-5.5',
                'mariadb-server-core-5.5',
            ]:
                ensure  => present,
                require => Apt::Repository['wikimedia-mariadb'],
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
