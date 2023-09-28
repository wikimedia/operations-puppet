class profile::mariadb::misc::multiinstance (
    Hash[String, Stdlib::Datasize] $instances = lookup('profile::mariadb::misc::multiinstance::instances'),
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

    $instances.each |$section, $buffer_pool| {
        $port = $section_ports[$section]
        if (!$port) {
            fail("'${section}' is not a valid section.")
        }
        $prom_port = Integer("1${port}")

        $template =  $section ? {
            default => undef,
            'm3' => 'profile/mariadb/mysqld_config/phabricator_instance.my.cnf.erb',
        }

        mariadb::instance { $section:
            port                    => $port,
            innodb_buffer_pool_size => $buffer_pool,
            template                => $template,
        }
        profile::mariadb::section { $section: mention_alias => true }
        profile::mariadb::ferm { $section: port => $port, }
        profile::prometheus::mysqld_exporter_instance { $section: port => $prom_port }
        profile::mariadb::replication_lag { $section: prom_port => $prom_port }

        if $section == 'm3' {
            # stopwords are stored prersistently and backed up, so no need to load it every time
            file { '/etc/mysql/phabricator-init.sql':
                ensure => present,
                owner  => 'root',
                group  => 'root',
                mode   => '0644',
                source => 'puppet:///modules/profile/mariadb/phabricator-init.sql',
            }
        }
    }

    class { 'mariadb::monitor_disk':
        is_critical   => false,
    }

    class { 'mariadb::monitor_process':
        process_count => length($instances),
        is_critical   => false,
    }
}
