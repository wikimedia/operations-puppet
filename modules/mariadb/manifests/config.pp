# Please use separate .cnf templates for each type of server.
# A maze of variables and if/then/else/end just confuses things,
# plus separate templates are easy to diff.

class mariadb::config {

    file { '/etc/my.cnf':
        content => template('mariadb/default.my.cnf.erb'),
    }

    file { '/etc/mysql/my.cnf':
        ensure => link,
        target => '/etc/my.cnf',
    }
}