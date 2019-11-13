# MariaDB packages for a client-only install.
# **Do not add it** if you do a full installation
# (packages.pp or packages_wmf.pp)

class mariadb::packages_client {

    package { [
        'percona-toolkit',       # very useful client utilities
        'grc',                   # used to colorize paged sql output
        'python3-pymysql',       # dependency for some utilities- TODO: delete & add as dependency
        'python3-tabulate',      # dependency for some utilities- TODO: delete & add as dependency
    ]:
        ensure => present,
    }

    if os_version('debian < stretch') {
        require_package('percona-xtrabackup',
                        'wmf-mariadb101-client')  # mariadb client, custom wmf package
    } elsif os_version('debian == stretch') {
        require_package('wmf-mariadb101-client')  # xtrabackup only available on wmf-mariadb101 server package
    } elsif os_version('debian >= buster') {
        require_package('mariadb-backup',
                        'wmf-mariadb104-client')
    }
}
