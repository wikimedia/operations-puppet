class profile::wmcs::db::wikireplicas::mariadb_multiinstance (
    Hash[String, Stdlib::Datasize] $instances = lookup('profile::wmcs::db::wikireplicas::mariadb_multiinstance::instances', ),
    Array[String] $mysql_root_clients = lookup('mysql_root_clients', {default_value =>[]}),
    Hash[String,Stdlib::Port] $section_ports = lookup('profile::mariadb::section_ports', ),
    Integer[0, 100] $mariadb_memory_warning_threshold = lookup('profile::wmcs::db::wikireplicas::mariadb_multiinstance::warning_threshold', {'default_value' => 90}),
    Integer[0, 100] $mariadb_memory_critical_threshold = lookup('profile::wmcs::db::wikireplicas::mariadb_multiinstance::critical_threshold', {'default_value' => 95}),
) {
    class { 'mariadb::service':
        override => "[Service]\nExecStartPre=/bin/sh -c \"echo 'mariadb main service is \
disabled, use mariadb@<instance_name> instead'; exit 1\"",
    }

    require ::profile::mariadb::mysql_role
    require ::profile::mariadb::packages_wmf

    class { 'mariadb::config':
        datadir                 => false,
        basedir                 => $profile::mariadb::packages_wmf::basedir,
        read_only               => 1,
        config                  => 'profile/wmcs/db/wikireplicas/wikireplicas_multiinstance.my.cnf.erb',
        p_s                     => 'on',
        ssl                     => 'puppet-cert',
        binlog_format           => 'ROW',
        innodb_change_buffering => 'none',
    }

    file { '/etc/mysql/mysqld.conf.d':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }
    $mysql_root_clients_str = join($mysql_root_clients, ' ')
    $instances.each |$section, $buffer_pool| {
        $port = $section_ports[$section]
        if (!$port) {
            fail("'${section}' is not a valid section.")
        }
        $prom_port = Integer("1${port}")
        mariadb::instance { $section:
            port                    => $port,
            innodb_buffer_pool_size => $buffer_pool,
        }
        profile::mariadb::section { $section: mention_alias => true }
        ferm::service { "mysql_admin_${section}":
            proto  => 'tcp',
            port   => $port,
            srange => "(${mysql_root_clients_str})",
        }
        ferm::service { "mysql_adm_alternate_${section}":
            proto  => 'tcp',
            port   => 20 + $port,
            srange => "(${mysql_root_clients_str})",
        }
        ferm::service { "mysql_wikireplica_db_proxy_${section}":
            proto   => 'tcp',
            port    => $port,
            notrack => true,
            srange  => '(@resolve((dbproxy1018.eqiad.wmnet)) @resolve((dbproxy1019.eqiad.wmnet)))',
        }
        ferm::service { "mysql_wmcs_db_admin_${section}":
            proto   => 'tcp',
            port    => $port,
            notrack => true,
            srange  => '(@resolve((labstore1004.eqiad.wmnet)) @resolve((labstore1005.eqiad.wmnet)))',
        }
        mariadb::monitor_readonly{ "wikireplica-${section}":
            port      => $port,
            read_only => 1,
        }
        profile::prometheus::mysqld_exporter_instance { $section: port => $prom_port, }
    }

    class { 'mariadb::monitor_disk':
        is_critical   => false,
        contact_group => 'admins,wmcs-bots',
    }

    class { 'mariadb::monitor_process':
        process_count => length($instances),
        is_critical   => false,
        contact_group => 'admins,wmcs-team-email',
    }

    class { 'mariadb::monitor_memory':
        contact_group => 'admins,wmcs-bots',
        warning       => $mariadb_memory_warning_threshold,
        critical      => $mariadb_memory_critical_threshold,
    }
}
