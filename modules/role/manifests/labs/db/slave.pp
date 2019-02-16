class role::labs::db::slave {

    system::role { 'labs::db::slave':
        description => 'Labs user database slave',
    }

    include ::standard
    class { '::mariadb::packages_wmf': }
    class { '::mariadb::service': }
    include ::profile::mariadb::monitor
    include ::role::mariadb::ferm
    include ::passwords::misc::scripts

    # FIXME: Add the socket location to make the transition easier.
    $socket = '/var/run/mysqld/mysqld.sock'

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        mysql_shard => 'tools',
        socket      => $socket,
    }

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/tools.my.cnf.erb',
        datadir       => '/srv/labsdb/data',
        tmpdir        => '/srv/labsdb/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
        socket        => $socket,
    }

    #mariadb::monitor_replication { 'tools':
    #    multisource   => false,
    #    contact_group => 'labs',
    #}

    $labs_networks = join($::network::constants::labs_networks, ' ')
    ferm::rule{'vm_db_access':
        ensure => 'present',
        rule   => "saddr (${labs_networks})
                          proto tcp dport 3306 ACCEPT;",
    }
    ferm::rule{'vm_rsync_access':
        ensure => 'present',
        rule   => "saddr (${labs_networks})
                          proto tcp dport 873 ACCEPT;",
    }
}

