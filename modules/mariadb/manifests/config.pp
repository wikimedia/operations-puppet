
# Please use separate .cnf templates for each type of server.
# Keep this independent and modular. It should be includable without the mariadb class.

class mariadb::config(
    $config   = 'default.my.cnf.erb',
    $prompt   = '',
    $password = 'undefined',
    $datadir  = '/srv/sqldata',
    $tmpdir   = '/srv/tmp',
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

    file { "$datadir":
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
    }

    file { "$tmpdir":
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
    }
}