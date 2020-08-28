class profile::mariadb::misc::multiinstance (
    $num_instances = hiera('profile::mariadb::misc::multiinstance::num_instances'),
    $m1            = hiera('profile::mariadb::misc::multiinstance::m1', false),
    $m2            = hiera('profile::mariadb::misc::multiinstance::m2', false),
    $m3            = hiera('profile::mariadb::misc::multiinstance::m3', false),
    $m5            = hiera('profile::mariadb::misc::multiinstance::m5', false),
) {
    require profile::mariadb::packages_wmf
    class { 'mariadb::service':
        override => "[Service]\nExecStartPre=/bin/sh -c \"echo 'mariadb main service is \
disabled, use mariadb@<instance_name> instead'; exit 1\"",
    }

    include ::profile::mariadb::mysql_role

    class { 'mariadb::config':
        datadir       => false,
        basedir       => $profile::mariadb::packages_wmf::basedir,
        read_only     => 'ON',
        config        => 'profile/mariadb/mysqld_config/misc_multiinstance.my.cnf.erb',
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

    if $m1 {
        mariadb::instance { 'm1':
            port                    => 3321,
            innodb_buffer_pool_size => $m1,
            # template                => 'profile/mariadb/mysqld_config/misc.my.cnf.erb'
        }
        profile::mariadb::section { 'm1': }
        profile::mariadb::ferm { 'm1': port => '3321' }
        profile::prometheus::mysqld_exporter_instance { 'm1': port => 13321, }
        profile::mariadb::replication_lag { 'm1': prom_port => 13321, }
    }
    if $m2 {
        mariadb::instance { 'm2':
            port                    => 3322,
            innodb_buffer_pool_size => $m2,
            # template                => 'profile/mariadb/mysqld_config/misc.my.cnf.erb'
        }
        profile::mariadb::section { 'm2': }
        profile::mariadb::ferm { 'm2': port => '3322' }
        profile::prometheus::mysqld_exporter_instance { 'm2': port => 13322, }
        profile::mariadb::replication_lag { 'm2': prom_port => 13322, }
    }
    if $m3 {
        mariadb::instance { 'm3':
            port                    => 3323,
            innodb_buffer_pool_size => $m3,
            template                => 'profile/mariadb/mysqld_config/phabricator_instance.my.cnf.erb',
        }
        profile::mariadb::section { 'm3': }
        profile::mariadb::ferm { 'm3': port => '3323' }
        profile::prometheus::mysqld_exporter_instance { 'm3': port => 13323, }
        profile::mariadb::replication_lag { 'm3': prom_port => 13323, }
        # stopwords are stored prersistently and backed up, so no need to load it every time
        file { '/etc/mysql/phabricator-init.sql':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/profile/mariadb/phabricator-init.sql',
        }
    }
    if $m5 {
        mariadb::instance { 'm5':
            port                    => 3325,
            innodb_buffer_pool_size => $m5,
            # template                => 'profile/mariadb/mysqld_config/misc.my.cnf.erb'
        }
        profile::mariadb::section { 'm5': }
        profile::mariadb::ferm { 'm5': port => '3325' }
        include profile::mariadb::ferm_wmcs_on_port_3325
        profile::prometheus::mysqld_exporter_instance { 'm5': port => 13325, }
        profile::mariadb::replication_lag { 'm5': prom_port => 13325, }
    }

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
