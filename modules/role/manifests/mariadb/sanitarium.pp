class role::mariadb::sanitarium {

    system::role { 'role::mariadb::sanitarium':
        description => 'Sanitarium DB Server',
    }

    include standard
    include passwords::misc::scripts
    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        config   => 'mariadb/sanitarium.my.cnf.erb',
    }

    ferm::service { 'mysqld_sanitarium':
        proto  => 'tcp',
        port   => '3311:3317',
        srange => '$INTERNAL',
    }

    ferm::service { 'gmond_udp':
        proto  => 'udp',
        port   => '8649',
        srange => '$INTERNAL',
    }

    ferm::service { 'gmond_tcp':
        proto  => 'tcp',
        port   => '8649',
        srange => '$INTERNAL',
    }

    # One instance per shard using mysqld_multi.
    # This allows us to send separate replication channels downstream.
    $folders = [
        '/srv/sqldata.s1',
        '/srv/sqldata.s2',
        '/srv/sqldata.s3',
        '/srv/sqldata.s4',
        '/srv/sqldata.s5',
        '/srv/sqldata.s6',
        '/srv/sqldata.s7',
        '/srv/tmp.s1',
        '/srv/tmp.s2',
        '/srv/tmp.s3',
        '/srv/tmp.s4',
        '/srv/tmp.s5',
        '/srv/tmp.s6',
        '/srv/tmp.s7',
    ]

    file { $folders:
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    # mysqld_multi wrapper
    file { '/etc/init.d/mariadb':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('mariadb/sanitarium.sysvinit.erb'),
    }
    file { '/etc/init.d/mysql':
        ensure => link,
        target => '/etc/init.d/mariadb',
    }

    class { 'mariadb::monitor_disk':
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        process_count => 7,
        contact_group => 'admins'
    }
}

