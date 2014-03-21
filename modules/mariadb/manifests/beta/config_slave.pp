class mariadb::beta::config_slave {

    include mariadb::config::debian

    file { '/etc/my.cnf':
        content => template('mariadb/default.my.cnf.erb'),
    }
}
