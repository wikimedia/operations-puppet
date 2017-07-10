# sanitarium 3 role: it replicates from all core shards (except x1), and
# sanitizes most data on production on 7 shards, before the data arrives to
# labs
# This role installs a 10.1 version which is needed for rbr triggers for
# the new sanitarium3 server, which runs multi-instance and mariadb 10.1

class role::mariadb::sanitarium3 {

    system::role { 'mariadb::sanitarium':
        description => 'Sanitarium DB Server',
    }

    include ::standard
    include passwords::misc::scripts
    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        socket      => '/tmp/mysql.s1.sock',
    }


    class {'mariadb::packages_wmf':
        package => 'wmf-mariadb101',
    }

    class { 'mariadb::config':
        basedir => '/opt/wmf-mariadb101',
        socket  => '/tmp/mysql.sock',
        config  => 'role/mariadb/mysqld_config/sanitarium3.my.cnf.erb',
        ssl     => 'puppet-cert',
    }

    class {'mariadb::service':
        package => 'wmf-mariadb101',
    }

    include role::labs::db::common
    include role::labs::db::check_private_data

    ferm::service { 'mysqld_sanitarium':
        proto  => 'tcp',
        port   => '3311:3317',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'gmond_udp':
        proto  => 'udp',
        port   => '8649',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'gmond_tcp':
        proto  => 'tcp',
        port   => '8649',
        srange => '$PRODUCTION_NETWORKS',
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
        content => template('role/mariadb/sanitarium3.sysvinit.erb'),
    }

    class { 'mariadb::monitor_disk':
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        process_count => 7,
        contact_group => 'admins',
    }
}

