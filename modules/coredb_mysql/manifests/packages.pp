# coredb_mysql required packages
class coredb_mysql::packages {
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
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
