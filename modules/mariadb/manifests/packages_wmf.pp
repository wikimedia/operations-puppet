# MariaDB WMF patched build installed in /opt.
# Unless you're setting up a production server, you probably want vanilla mariadb::packages

class mariadb::packages_wmf(
    $mariadb10 = false,
    ) {

    package { [
        'libaio1',
        'libmysqlclient18',
        'mysql-client-5.5',
        'percona-toolkit',
        'percona-xtrabackup',
    ]:
        ensure => present,
    }

    if ($mariadb10 == true) {

        package { [
            'wmf-mariadb10',
        ]:
            ensure => present,
        }
    }
    else {

        package { [
            'wmf-mariadb',
        ]:
            ensure => present,
        }
    }
}