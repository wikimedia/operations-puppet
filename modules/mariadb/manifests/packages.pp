class mariadb::packages {

    package { [
        'libmariadbclient18',
        'mariadb-client-5.5',
        'mariadb-server-5.5',
        'mariadb-server-core-5.5',
        'percona-toolkit',
        'percona-xtrabackup',
    ]:
        ensure  => present,
        require => File['/etc/apt/sources.list.d/wikimedia-mariadb.list'],
    }
}