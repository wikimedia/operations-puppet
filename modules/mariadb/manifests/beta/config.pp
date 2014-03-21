# Please use separate .cnf templates for each type of server.
# A maze of variables and if/then/else/end just confuses things,
# plus separate templates are easy to diff.

class mariadb::beta::config inherits mariadb::config {

    File['/etc/my.cnf'] {
        content => template('mariadb/beta.my.cnf.erb'),
    }
}

class mariadb::beta::config_slave inherits mariadb::config {

    File['/etc/my.cnf'] {
        content => template('mariadb/beta_slave.my.cnf.erb'),
    }
}
