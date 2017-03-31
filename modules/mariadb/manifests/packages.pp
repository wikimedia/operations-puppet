# MariaDB 5.5 debs
# These are not used on production (packages_wmf.pp is used instead).

class mariadb::packages {

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
