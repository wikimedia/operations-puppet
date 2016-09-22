class mysql_wmf::pc::conf inherits mysql_wmf {
    file { '/etc/my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mysql_wmf/parsercache.my.cnf.erb'),
    }
    file { '/etc/mysql/my.cnf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mysql_wmf/empty-my.cnf',
    }
}

