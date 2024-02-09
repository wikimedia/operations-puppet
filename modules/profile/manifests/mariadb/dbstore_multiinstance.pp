class profile::mariadb::dbstore_multiinstance (
    Hash[String, Stdlib::Datasize] $instances = lookup('profile::mariadb::dbstore_multiinstance::instances'),
    Hash[String, Stdlib::Port] $section_ports = lookup('profile::mariadb::section_ports'),
) {
    require profile::mariadb::packages_wmf
    class { 'mariadb::service':
        override => "[Service]\nExecStartPre=/bin/sh -c \"echo 'mariadb main service is \
disabled, use mariadb@<instance_name> instead'; exit 1\"",
    }

    include ::profile::mariadb::mysql_role
    include profile::mariadb::wmfmariadbpy

    class { 'mariadb::config':
        datadir       => false,
        basedir       => $profile::mariadb::packages_wmf::basedir,
        read_only     => 1,
        config        => 'profile/mariadb/mysqld_config/dbstore_multiinstance.my.cnf.erb',
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

    # Note for Analytics dbstores:
    #
    # In case you change the following settings, please make sure
    # that the following is consistent:
    # 1) Analytics' DNS CNAMEs and SRV records
    # 2) Analytics VLAN's firewall rules
    # For more info ping one of the Data Platform SREs.

    $instances.each |$section, $buffer_pool| {
        $port = $section_ports[$section]
        if (!$port) {
            fail("'${section}' is not a valid section.")
        }
        $prom_port = Integer("1${port}")

        $read_only = $section ? {
            default => undef,
            'staging' => 0,
        }

        mariadb::instance { $section:
            port                    => $port,
            innodb_buffer_pool_size => $buffer_pool,
            read_only               => $read_only,
        }
        profile::mariadb::section { $section: mention_alias => true }
        profile::mariadb::ferm { $section: port => $port, }
        profile::prometheus::mysqld_exporter_instance { $section: port => $prom_port }
    }

    class { 'mariadb::monitor_disk': }

    class { 'mariadb::monitor_process':
        process_count => length($instances),
    }

    class { 'mariadb::monitor_memory': }
}
