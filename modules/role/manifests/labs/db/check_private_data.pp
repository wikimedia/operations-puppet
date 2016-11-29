class role::labs::db::check_private_data {

    file { '/etc/mysql/private_tables.txt':
        ensure  => file,
        content => template('role/mariadb/private_tables.txt.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file { '/etc/mysql/filtered_columns.txt':
        ensure => file,
        source => 'puppet:///modules/role/mariadb/filtered_columns.txt'),
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/usr/local/sbin/check_private_data.py':
        ensure  => file,
        source  => 'puppet:///modules/role/mariadb/check_private_data.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        require => [
                       Package['python3-yaml', 'python3-pymysql'],
                       Git::clone['operations/mediawiki-config'],
                       File['/etc/mysql/filtered_columns.txt'],
                       File['/etc/mysql/private_tables.txt'],
                   ],
    }
}
