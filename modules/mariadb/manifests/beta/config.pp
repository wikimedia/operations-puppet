# Please use separate .cnf templates for each type of server.
# A maze of variables and if/then/else/end just confuses things,
# plus separate templates are easy to diff.

class mariadb::beta::config {

    include mariadb::config::debian

    file { '/etc/my.cnf':
        content => template('mariadb/default.my.cnf.erb'),
    }
}