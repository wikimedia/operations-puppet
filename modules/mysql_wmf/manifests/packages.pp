
# These classes contain a bunch of stuff that's specific to
# the wmf production DB systems.  If you want to construct
# a general-purpose DB server or client, best look elsewhere.

class mysql_wmf::packages {
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
