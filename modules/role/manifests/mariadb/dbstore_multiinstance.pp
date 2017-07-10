class role::mariadb::dbstore_multiinstance {
    system::role { 'mariadb::core':
        description => 'DBStore multi-instance server',
    }

    include ::standard
    include ::base::firewall
    include role::mariadb::monitor
    #TODO: Custom firewall rules

    #TODO: define one group per shard
    class {'mariadb::groups':
        mysql_group => 'dbstore',
        mysql_shard => 's1',
        mysql_role  => 'slave',
        socket      => '/run/mysqld/mysqld.s1.sock',
    }

    class {'mariadb::packages_wmf': }
    class {'mariadb::service':
        # multiinstance => true, # for now, we will not do anything special
        # for now we will keep things simple, we probably should have a
        # higher-level interface with templates
        override      => "[Service]\nLimitNOFILE=200000",
    }

    # Read only forced on also for the masters of the primary datacenter
    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/dbstore3.my.cnf.erb',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

    mariadb::instance {'s1':
        port => 3311,
    }
    mariadb::instance {'s2':
        port => 3312,
    }
    mariadb::instance {'s3':
        port => 3313,
    }
    mariadb::instance {'s4':
        port => 3314,
    }
    mariadb::instance {'s5':
        port => 3315,
    }
    mariadb::instance {'s6':
        port => 3316,
    }
    mariadb::instance {'s7':
        port => 3317,
    }
}
