class mysql_wmf::ganglia(
    $mariadb = false,
    ) {
    include passwords::ganglia
    $ganglia_mysql_pass = $passwords::ganglia::ganglia_mysql_pass

    if $mariadb {
        $innodb_version = '55xdb'
    }

    # Ganglia
    package { 'python-mysqldb':
        ensure => present;
    }

    # FIXME: this belongs in ganglia.pp, not here.
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '8.04') == 0 {
        file { '/etc/ganglia':
                ensure => directory,
                owner  => 'root',
                group  => 'root',
                mode   => '0755',
        }
        file { '/etc/ganglia/conf.d':
                ensure => directory,
                owner  => 'root',
                group  => 'root',
                mode   => '0755',
        }
        file { '/usr/lib/ganglia/python_modules':
                ensure => directory,
                owner  => 'root',
                group  => 'root',
                mode   => '0755',
        }
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
    file { '/etc/ganglia/conf.d/mysql.pyconf':
            require => File['/usr/lib/ganglia/python_modules'],
            content => template('mysql_wmf/mysql.pyconf.erb'),
            notify  => Service['gmond'],
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
    }
}
