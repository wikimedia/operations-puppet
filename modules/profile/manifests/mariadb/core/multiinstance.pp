class profile::mariadb::core::multiinstance(
    Hash[String, Stdlib::Datasize] $instances = lookup('profile::mariadb::core::multiinstance::instances'),
    Hash[String, Stdlib::Port] $section_ports = lookup('profile::mariadb::section_ports'),
    String $wikiadmin_username = lookup('profile::mariadb::wikiadmin_username'),
    String $wikiuser_username = lookup('profile::mariadb::wikiuser_username'),
) {
    require profile::mariadb::packages_wmf
    class { 'mariadb::service':
        override => "[Service]\nExecStartPre=/bin/sh -c \"echo 'mariadb main service is \
disabled, use mariadb@<instance_name> instead'; exit 1\"",
    }

    include ::profile::mariadb::mysql_role
    include profile::mariadb::wmfmariadbpy
    require passwords::misc::scripts

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
        $is_critical = profile::mariadb::section_params::is_writeable_dc($section)
        mariadb::instance { $section:
            port                    => $port,
            innodb_buffer_pool_size => $buffer_pool,
            is_critical             => $is_critical,
            source_dc               => $::site,
        }
        profile::mariadb::section { $section: mention_alias => true }
        profile::mariadb::ferm { $section: port => $port }
        profile::prometheus::mysqld_exporter_instance { $section: port => $prom_port }
        profile::mariadb::replication_lag { $section: prom_port => $prom_port }
        profile::mariadb::grants::core { $section:
            wikiadmin_username => $wikiadmin_username,
            wikiadmin_pass     => $passwords::misc::scripts::wikiadmin_pass,
            wikiuser_username  => $wikiuser_username,
            wikiuser_pass      => $passwords::misc::scripts::wikiuser_pass,
        }
    }

    $is_critical = $instances.any |$section, $buffer_pool| {
        profile::mariadb::section_params::is_writeable_dc($section)
    }

    class { 'mariadb::monitor_disk':
        is_critical   => $is_critical,
    }

    class { 'mariadb::monitor_process':
        process_count => length($instances),
        is_critical   => $is_critical,
    }

    class { 'mariadb::monitor_memory': }
}
