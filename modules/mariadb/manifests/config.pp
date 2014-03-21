# Please use separate .cnf templates for each type of server.

class mariadb::config(
	$config   = 'default.my.cnf.erb',
	$prompt   = '',
	$password = 'undefined',
	) {

    file { '/etc/my.cnf':
        content => template("mariadb/$config"),
    }

    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template("mariadb/root.my.cnf.erb"),
    }

    file { '/etc/mysql/my.cnf':
        ensure => link,
        target => '/etc/my.cnf',
    }
}