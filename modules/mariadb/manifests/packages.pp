# MariaDB 5.5 debs
# Keep this independent and modular. It should be includable without the mariadb class.

class mariadb::packages {

    apt::repository { 'wikimedia_mariadb':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => 'precise-wikimedia',
        components => 'mariadb',
    }

    package { [
        'libmariadbclient18',
        'mariadb-client-5.5',
        'mariadb-server-5.5',
        'mariadb-server-core-5.5',
        'percona-toolkit',
        'percona-xtrabackup',
    ]:
        ensure => present,
    }
}