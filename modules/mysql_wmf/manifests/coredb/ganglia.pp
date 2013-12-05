class mysql_wmf::coredb::ganglia(
    $mariadb = false
    ) {

    include passwords::ganglia
    $ganglia_mysql_pass = $passwords::ganglia::ganglia_mysql_pass

    if $mariadb {
        $innodb_version = '55xdb'
    }

    # Ganglia
    package { 'python-mysqldb':
        ensure => present,
    }

    file { '/usr/lib/ganglia/python_modules/DBUtil.py':
            require => File['/usr/lib/ganglia/python_modules'],
            source  => 'puppet:///modules/mysql_wmf/ganglia/plugins/DBUtil.py',
            notify  => Service['gmond'],
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
    }
    file { '/usr/lib/ganglia/python_modules/mysql.py':
            require => File['/usr/lib/ganglia/python_modules'],
            source  => 'puppet:///modules/mysql_wmf/ganglia/plugins/mysql.py',
            notify  => Service['gmond'],
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
    }
    file{ '/etc/ganglia/conf.d/mysql.pyconf':
            require => File['/usr/lib/ganglia/python_modules'],
            content => template('mysql_wmf/mysql.pyconf.erb'),
            notify  => Service['gmond'],
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
    }
}
