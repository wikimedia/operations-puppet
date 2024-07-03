# Class profile::mariadb::misc::analytics::multiinstance
#
# The Analytics team manages multiple small databases related to their
# tools (Superset, Druid, Matomo, etc..) and this profile implements
# a mariadb multi-instance environment that can be used as replica.
#
# This class is used to do MariaDB logical backups via profile::dbbackups::mydumper.
# (As of 2024-07, dbprov1004 is taking remote backups.)
# See: https://wikitech.wikimedia.org/wiki/MariaDB/Backups#Logical_backups
#
class profile::mariadb::misc::analytics::multiinstance (
    Hash[String, Hash] $instances = lookup('profile::mariadb::misc::analytics::multiinstance::instances'),
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
        basedir            => $profile::mariadb::packages_wmf::basedir,
        config             => 'profile/mariadb/mysqld_config/analytics_multiinstance.my.cnf.erb',
        p_s                => 'on',
        ssl                => 'puppet-cert',
        # MUST use ROW, hive metastore database is not compatible with other kinds.
        binlog_format      => 'ROW',
        max_allowed_packet => '32M',
        read_only          => 1,
    }

    file { '/etc/mysql/mysqld.conf.d':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    $instances.each |$section, $instance_params| {
        $port = $section_ports[$section]
        if (!$port) {
            fail("'${section}' is not a valid section.")
        }
        $prom_port = Integer("1${port}")

        # $section port will always override anything in $instance_params.
        $mariadb_instance_params = deep_merge(
            $instance_params,
            { 'port' => $port },
        )

        # Declare a mariadb::instance named $section with $mariadb_instance_params.
        create_resources('mariadb::instance', { $section => $mariadb_instance_params })
        profile::mariadb::section { $section: mention_alias => true }
        profile::mariadb::ferm { $section: port => $port }
        profile::prometheus::mysqld_exporter_instance { $section: port => $prom_port }
    }

    class { 'mariadb::monitor_disk':
        is_critical   => false,
        contact_group => 'admins,team-data-platform',
    }

    class { 'mariadb::monitor_process':
        process_count => length($instances),
        is_critical   => false,
        contact_group => 'admins,team-data-platform',
    }

    class { 'mariadb::monitor_memory': }
}
