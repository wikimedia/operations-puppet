# Please use separate .cnf templates for each type of server.
# A maze of variables and if/then/else/end just confuses things,
# plus separate templates are easy to diff.

class mariadb::tendril::config inherits mariadb::config {

	include passwords::misc::scripts
    include mariadb::config::debian

    file { '/etc/my.cnf':
        content => template('mariadb/default.my.cnf.erb'),
    }

    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('mariadb/root.my.cnf.erb'),
    }
}
