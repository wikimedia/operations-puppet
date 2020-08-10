# Class profile::mariadb::misc::analytics::multiinstance
#
# The Analytics team manages multiple small databases related to their
# tools (Superset, Druid, Matomo, etc..) and this profile implements
# a mariadb multi-instance environment that can be used as replica.
#
class profile::mariadb::misc::analytics::multiinstance (
    Integer $num_instances           = lookup('profile::mariadb::misc::analytics::multiinstance::num_instances'),
    Optional[String] $matomo         = lookup('profile::mariadb::misc::analytics::multiinstance::matomo', { 'default_value' => undef }),
    Optional[String] $analytics_meta = lookup('profile::mariadb::misc::analytics::multiinstance::analytics_meta', { 'default_value' => undef }),
) {
    class { 'mariadb::packages_wmf': }
    class { 'mariadb::service':
        override => "[Service]\nExecStartPre=/bin/sh -c \"echo 'mariadb main service is \
disabled, use mariadb@<instance_name> instead'; exit 1\"",
    }

    include ::profile::mariadb::mysql_role

    $basedir = '/opt/wmf-mariadb104'
    class { 'mariadb::config':
        basedir       => $basedir,
        config        => 'profile/mariadb/mysqld_config/misc_multiinstance.my.cnf.erb',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
        read_only     => 1,
    }

    file { '/etc/mysql/mysqld.conf.d':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    if $matomo {
        mariadb::instance { 'matomo':
            port                    => 3351,
            innodb_buffer_pool_size => $matomo,
        }
        profile::mariadb::section { 'matomo': }
        profile::mariadb::ferm { 'matomo': port => '3351' }
        profile::prometheus::mysqld_exporter_instance { 'matomo': port => 13351, }
    }
    if $analytics_meta {
        mariadb::instance { 'analytics_meta':
            port                    => 3352,
            innodb_buffer_pool_size => $analytics_meta,
        }
        profile::mariadb::section { 'analytics_meta': }
        profile::mariadb::ferm { 'analytics_meta': port => '3352' }
        profile::prometheus::mysqld_exporter_instance { 'analytics_meta': port => 13352, }
    }

    class { 'mariadb::monitor_disk':
        is_critical   => false,
        contact_group => 'admins,analytics',
    }

    class { 'mariadb::monitor_process':
        process_count => $num_instances,
        is_critical   => false,
        contact_group => 'admins,analytics',
    }

    class { 'mariadb::monitor_memory': }
}
