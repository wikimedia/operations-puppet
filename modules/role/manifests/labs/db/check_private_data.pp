# Deploy script and dependencies needed to check no private data
# persists on the database
class role::labs::db::check_private_data {

    file { '/etc/mysql/private_tables.txt':
        ensure  => file,
        content => template('role/mariadb/private_tables.txt.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file { '/etc/mysql/filtered_tables.txt':
        ensure => file,
        source => 'puppet:///modules/role/mariadb/filtered_tables.txt',
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
        require => [Package['python3-yaml', 'python3-pymysql'],
                    Git::Clone['operations/mediawiki-config'],
                    File['/etc/mysql/filtered_tables.txt'],
                    File['/etc/mysql/private_tables.txt'],
        ],
    }

    file { '/usr/local/sbin/check_private_data_report':
        ensure => file,
        source => 'puppet:///modules/role/mariadb/check_private_data_report',
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }

    cron { 'check-private-data':
        minute  => 0,
        hour    => 5,
        weekday => 1,
        user    => 'root',
        command => '/usr/local/sbin/check_private_data_report > /dev/null 2>&1',
        require => [File['/usr/local/sbin/check_private_data_report'],
                    File['/usr/local/sbin/check_private_data.py'],
        ],
    }

}
