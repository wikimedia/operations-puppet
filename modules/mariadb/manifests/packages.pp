# MariaDB debs
# These are not used on production (packages_wmf.pp is used instead).

class mariadb::packages {

    ensure_packages([
        'mariadb-client',
        'mariadb-server',
        'percona-toolkit',
        # 'percona-xtrabackup',
    ])
}
