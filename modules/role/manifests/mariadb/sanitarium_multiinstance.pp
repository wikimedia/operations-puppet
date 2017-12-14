# sanitarium_multiinstance: it replicates from all core shards (except x1),
# and sanitizes most data on production on 7 shards, before the data
# arrives to labs
# This role installs a 10.1 version which is needed for rbr triggers for
# the new sanitarium server, which runs multi-instance and mariadb 10.1
# Eventually, this role will deprecate the original sanitarium and
# sanitarium2/sanitarium_multisource

class role::mariadb::sanitarium_multiinstance {

    system::role { 'mariadb::sanitarium':
        description => 'Sanitarium DB Server',
    }

    include ::standard
    include ::base::firewall
    #FIXME:
    ferm::service { 'sanitarium_multiinstance':
        proto  => 'tcp',
        port   => '3311:3320',
        srange => '$PRODUCTION_NETWORKS',
    }

    #TODO: define one group per shard
    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        socket      => '/run/mysqld/mysqld.s2.sock',
    }

    include role::labs::db::common
    include role::labs::db::check_private_data

    class { 'mariadb::packages_wmf': }
    # disable starting a default instance
    class {'mariadb::service':
        override => "[Service]\nExecStartPre=/bin/sh -c \"echo 'mariadb main service is \
disabled, use mariadb@<instance_name> instead'; exit 1\"",
    }

    if os_version('debian >= stretch') {
        $basedir = '/opt/wmf-mariadb101'
    } else {
        $basedir = '/opt/wmf-mariadb10'
    }
    class { 'mariadb::config':
        basedir       => $basedir,
        config        => 'role/mariadb/mysqld_config/sanitarium_multiinstance.my.cnf.erb',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

    mariadb::instance {'s2':
        port => 3312,
    }
    role::prometheus::mysqld_exporter_instance {'s2':
        port => 13312,
    }
    mariadb::instance {'s4':
        port => 3314,
    }
    role::prometheus::mysqld_exporter_instance {'s4':
        port => 13314,
    }
    mariadb::instance {'s6':
        port => 3316,
    }
    role::prometheus::mysqld_exporter_instance {'s6':
        port => 13316,
    }
    mariadb::instance {'s7':
        port => 3317,
    }
    role::prometheus::mysqld_exporter_instance {'s7':
        port => 13317,
    }

    class { 'mariadb::monitor_disk':
        is_critical   => false,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        process_count => 4,
        contact_group => 'admins',
    }
}

