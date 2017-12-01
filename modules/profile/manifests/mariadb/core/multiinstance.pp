# TODO: use a data structure for the shards
class profile::mariadb::core::multiinstance(
    $num_instances = hiera('profile::mariadb::core_multiinstance::num_instances', 2),
    $s1 = hiera('profile::mariadb::core_multiinstance::s1', false),
    $s2 = hiera('profile::mariadb::core_multiinstance::s2', false),
    $s3 = hiera('profile::mariadb::core_multiinstance::s3', false),
    $s4 = hiera('profile::mariadb::core_multiinstance::s4', false),
    $s5 = hiera('profile::mariadb::core_multiinstance::s5', false),
    $s6 = hiera('profile::mariadb::core_multiinstance::s6', false),
    $s7 = hiera('profile::mariadb::core_multiinstance::s7', false),
    $s8 = hiera('profile::mariadb::core_multiinstance::s8', false),
    $x1 = hiera('profile::mariadb::core_multiinstance::x1', false),
) {
    #FIXME:
    ferm::service { 'core_multiinstance':
        proto  => 'tcp',
        port   => '3311:3320',
        srange => '$PRODUCTION_NETWORKS',
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
        config        => 'profile/mariadb/mysqld_config/core_multiinstance.my.cnf.erb',
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


    if $s1 {
        mariadb::instance { 's1':
            port                    => 3311,
            innodb_buffer_pool_size => $s1,
        }
        role::prometheus::mysqld_exporter_instance {'s1': port => 13311, }
    }

    if $s2 {
        mariadb::instance { 's2':
            port                    => 3312,
            innodb_buffer_pool_size => $s2,
        }
        role::prometheus::mysqld_exporter_instance { 's2': port => 13312, }
    }

    if $s3 {
        mariadb::instance { 's3':
            port                    => 3313,
            innodb_buffer_pool_size => $s2,
        }
        role::prometheus::mysqld_exporter_instance {'s3': port => 13313, }
    }

    if $s4 {
        mariadb::instance { 's4':
            port                    => 3314,
            innodb_buffer_pool_size => $s4,
        }
        role::prometheus::mysqld_exporter_instance { 's4': port => 13314, }
    }

    if $s5 {
        mariadb::instance { 's5':
            port                    => 3315,
            innodb_buffer_pool_size => $s5,
        }
        role::prometheus::mysqld_exporter_instance { 's5': port => 13315, }
    }

    if $s6 {
        mariadb::instance { 's6':
            port                    => 3316,
            innodb_buffer_pool_size => $s6,
        }
        role::prometheus::mysqld_exporter_instance { 's6': port => 13316, }
    }

    if $s7 {
        mariadb::instance { 's7':
            port                    => 3317,
            innodb_buffer_pool_size => $s7,
        }
        role::prometheus::mysqld_exporter_instance { 's7': port => 13317, }
    }

    if $s8 {
        mariadb::instance { 's8':
            port                    => 3318,
            innodb_buffer_pool_size => $s8,
        }
        role::prometheus::mysqld_exporter_instance { 's8': port => 13318, }
    }

    if $x1 {
        mariadb::instance { 'x1':
            port                    => 3320,
            innodb_buffer_pool_size => '5G',
        }
        role::prometheus::mysqld_exporter_instance { 'x1': port => 13320, }
    }

    require_package ('mydumper')

    class { 'mariadb::monitor_disk':
        is_critical   => true,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        process_count => $num_instances,
        is_critical   => true,
        contact_group => 'admins',
    }

}
