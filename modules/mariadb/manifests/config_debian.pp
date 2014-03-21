# MySQL & MariaDB raditionally use /etc/my.cnf. Certain debian packages 
# look for /etc/mysql/my.cnf.  Symlink it.

class mariadb::config::debian {

    file { '/etc/mysql/my.cnf':
        ensure => link,
        target => '/etc/my.cnf',
    }
}