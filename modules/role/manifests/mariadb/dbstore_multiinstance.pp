class role::mariadb::dbstore_multiinstance {
    system::role { 'mariadb::core':
        description => 'DBStore multi-instance server',
    }

    include ::standard
    class { 'profile::base::firewall': }
    #FIXME:
    ferm::service { 'dbstore_multiinstance':
        proto  => 'tcp',
        port   => '3311:3320',
        srange => '$PRODUCTION_NETWORKS',
    }

    #TODO: define one group per shard
    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'dbstore',
        mysql_shard => 's1',
        mysql_role  => 'slave',
        socket      => '/run/mysqld/mysqld.s1.sock',
    }

    class { 'mariadb::packages_wmf': }
    class { 'mariadb::service':
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
        config        => 'role/mariadb/mysqld_config/dbstore_multiinstance.my.cnf.erb',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

    file { '/etc/mysql/mysqld.conf.d':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    $s1 = hiera('role::mariadb::dbstore_multiinstance::s1', false)
    if $s1 {
        mariadb::instance { 's1':
            port                    => 3311,
            innodb_buffer_pool_size => $s1,
        }
        role::prometheus::mysqld_exporter_instance {'s1': port => 13311, }
    }
    $s2 = hiera('role::mariadb::dbstore_multiinstance::s2', false)
    if $s2 {
        mariadb::instance { 's2':
            port                    => 3312,
            innodb_buffer_pool_size => $s2,
        }
        role::prometheus::mysqld_exporter_instance { 's2': port => 13312, }
    }
    $s3 = hiera('role::mariadb::dbstore_multiinstance::s3', false)
    if $s3 {
        mariadb::instance { 's3':
            port                    => 3313,
            innodb_buffer_pool_size => $s2,
        }
        role::prometheus::mysqld_exporter_instance {'s3': port => 13313, }
    }
    $s4 = hiera('role::mariadb::dbstore_multiinstance::s4', false)
    if $s4 {
        mariadb::instance { 's4':
            port                    => 3314,
            innodb_buffer_pool_size => $s4,
        }
        role::prometheus::mysqld_exporter_instance { 's4': port => 13314, }
    }
    $s5 = hiera('role::mariadb::dbstore_multiinstance::s5', false)
    if $s5 {
        mariadb::instance { 's5':
            port                    => 3315,
            innodb_buffer_pool_size => $s5,
        }
        role::prometheus::mysqld_exporter_instance { 's5': port => 13315, }
    }
    $s6 = hiera('role::mariadb::dbstore_multiinstance::s6', false)
    if $s6 {
        mariadb::instance { 's6':
            port                    => 3316,
            innodb_buffer_pool_size => $s6,
        }
        role::prometheus::mysqld_exporter_instance { 's6': port => 13316, }
    }
    $s7 = hiera('role::mariadb::dbstore_multiinstance::s7', false)
    if $s7 {
        mariadb::instance { 's7':
            port                    => 3317,
            innodb_buffer_pool_size => $s7,
        }
        role::prometheus::mysqld_exporter_instance { 's7': port => 13317, }
    }
    $s8 = hiera('role::mariadb::dbstore_multiinstance::s8', false)
    if $s8 {
        mariadb::instance { 's8':
            port                    => 3318,
            innodb_buffer_pool_size => $s8,
        }
        role::prometheus::mysqld_exporter_instance { 's8': port => 13318, }
    }

    $x1 = hiera('role::mariadb::dbstore_multiinstance::x1', false)
    if $x1 {
        mariadb::instance { 'x1':
            port                    => 3320,
            innodb_buffer_pool_size => '5G',
        }
        role::prometheus::mysqld_exporter_instance { 'x1': port => 13320, }
    }

    require_package ('mydumper')

    class { 'mariadb::monitor_disk':
        is_critical   => false,
        contact_group => 'admins',
    }

    $num_instances = hiera('role::mariadb::dbstore_multiinstance::num_instances', 8)
    class { 'mariadb::monitor_process':
        process_count => $num_instances,
        is_critical   => false,
        contact_group => 'admins',
    }
}
