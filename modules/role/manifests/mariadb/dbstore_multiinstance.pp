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
        override => "[Service]\nExecStartPre=/bin/sh -c \"echo 'mariadb main service is \
disabled, use mariadb@<instance_name> instead'; exit 1\"",
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

    mariadb::instance {'s1': port => 3311, }
    role::prometheus::mysqld_exporter_instance {'s1': port => 13311, }
    mariadb::instance {'s2': port => 3312, }
    role::prometheus::mysqld_exporter_instance {'s2': port => 13312, }
    mariadb::instance {'s3': port => 3313, }
    role::prometheus::mysqld_exporter_instance {'s3': port => 13313, }
    mariadb::instance {'s4': port => 3314, }
    role::prometheus::mysqld_exporter_instance {'s4': port => 13314, }
    mariadb::instance {'x1':
        port                    => 3320,
        innodb_buffer_pool_size => '5G',
    }
    role::prometheus::mysqld_exporter_instance {'x1': port => 13320, }

    if $::hostname != 'dbstore2002' {
        $num_instances = 8
        mariadb::instance {'s5': port => 3315, }
        role::prometheus::mysqld_exporter_instance {'s5': port => 13315, }
        mariadb::instance {'s6': port => 3316, }
        role::prometheus::mysqld_exporter_instance {'s6': port => 13316, }
        mariadb::instance {'s7': port => 3317, }
        role::prometheus::mysqld_exporter_instance {'s7': port => 13317, }
    } else {
        $num_instances = 5
    }

    require_package ('mydumper')

    class { 'mariadb::monitor_disk':
        is_critical   => false,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        process_count => $num_instances,
        is_critical   => false,
        contact_group => 'admins',
    }
}
