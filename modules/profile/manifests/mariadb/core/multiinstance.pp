class profile::mariadb::core::multiinstance(
    Hash[String, Stdlib::Datasize] $instances = lookup('profile::mariadb::core::multiinstance::instances'),
    Hash[String, Stdlib::Port] $section_ports = lookup('profile::mariadb::section_ports'),
) {
    require profile::mariadb::packages_wmf
    class { 'mariadb::service':
        override => "[Service]\nExecStartPre=/bin/sh -c \"echo 'mariadb main service is \
disabled, use mariadb@<instance_name> instead'; exit 1\"",
    }

    include ::profile::mariadb::mysql_role
    include profile::mariadb::wmfmariadbpy

    $is_critical = ($::site == mediawiki::state('primary_dc'))
    $contact_group = 'admins'

    # Read only forced on also for the masters of the primary datacenter
    class { 'mariadb::config':
        datadir       => false,
        basedir       => $profile::mariadb::packages_wmf::basedir,
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

    $instances.each |$section, $buffer_pool| {
        $port = $section_ports[$section]
        if (!$port) {
            fail("'${section}' is not a valid section.")
        }
        $prom_port = Integer("1${port}")
        mariadb::instance { $section:
            port                    => $port,
            innodb_buffer_pool_size => $buffer_pool,
            is_critical             => $is_critical,
        }
        profile::mariadb::section { $section: }
        profile::mariadb::ferm { $section: port => $port }
        profile::prometheus::mysqld_exporter_instance { $section: port => $prom_port }
        profile::mariadb::replication_lag { $section: prom_port => $prom_port }
    }

    class { 'mariadb::monitor_disk':
        is_critical   => $is_critical,
        contact_group => $contact_group,
    }

    class { 'mariadb::monitor_process':
        process_count => length($instances),
        is_critical   => $is_critical,
        contact_group => $contact_group,
    }

    class { 'mariadb::monitor_memory': }
}
