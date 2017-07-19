class role::mariadb::dbstore_multiinstance {
    system::role { 'mariadb::core':
        description => 'DBStore multi-instance server',
    }

    include ::standard
    include ::base::firewall
    #FIXME:
    ferm::service { 'dbstore_multiinstance':
        proto  => 'tcp',
        port   => '3311:3320',
        srange => '$PRODUCTION_NETWORKS',
    }
    # Temporary extra instance on port 3306:
    include role::mariadb::ferm

    #TODO: define one group per shard
    class {'mariadb::groups':
        mysql_group => 'dbstore',
        mysql_shard => 's1',
        mysql_role  => 'slave',
        socket      => '/run/mysqld/mysqld.s1.sock',
    }

    class {'mariadb::packages_wmf': }
    class {'mariadb::service':
        override => "ExecStartPre=/bin/sh -c \"echo 'mariadb main service is disabled, \
use mariadb@<instance_name> instead'; exit 1\"",
    }

    if os_version('debian >= stretch') {
        $basedir = '/opt/wmf-mariadb101'
    } else {
        $basedir = '/opt/wmf-mariadb10'
    }
    # Read only forced on also for the masters of the primary datacenter
    class { 'mariadb::config':
        basedir       => $basedir,
        config        => 'role/mariadb/mysqld_config/dbstore3.my.cnf.erb',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

    file {'/etc/mysql/mysqld.conf.d':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }
    mariadb::instance {'s1':
        port => 3311,
    }
    mariadb::instance {'s2':
        port => 3312,
    }
    #mariadb::instance {'s3':
    #    port => 3313,
    #}
    #mariadb::instance {'s4':
    #    port => 3314,
    #}
    #mariadb::instance {'s5':
    #    port => 3315,
    #}
    #mariadb::instance {'s6':
    #    port => 3316,
    #}
    #mariadb::instance {'s7':
    #    port => 3317,
    #}
    mariadb::instance {'x1':
        port => 3320,
    }

    class { 'mariadb::monitor_disk':
        is_critical   => false,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        process_count => 3,
        is_critical   => false,
        contact_group => 'admins',
    }
}
