# MariaDB packages for a client-only install.
# **Do not add it** if you do a full installation
# (packages.pp or packages_wmf.pp)

class mariadb::packages_client {

    package { [
        'wmf-mariadb101-client',
        'percona-toolkit',
        'percona-xtrabackup',
        'grc',
        'python3-pymysql',
        'python3-tabulate',
    ]:
        ensure => present,
    }

}
