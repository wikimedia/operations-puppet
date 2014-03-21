class mariadb::sources {

    file { '/etc/apt/sources.list.d/wikimedia-mariadb.list':
        group  => 'root',
        mode   => '0444',
        owner  => 'root',
        source => 'puppet:///modules/mariadb/wikimedia-mariadb.list',
    }

    exec { 'update_mysql_apt':
        subscribe   => File['/etc/apt/sources.list.d/wikimedia-mariadb.list'],
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }
}