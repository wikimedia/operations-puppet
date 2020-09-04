# miscellaneous services clusters
class role::mariadb::misc {
    $shard = lookup('mariadb::shard')

    system::role { 'mariadb::misc':
        description => "Misc Services Database ${shard}",
    }

    include ::profile::mariadb::mysql_role

    $is_master = $profile::mariadb::mysql_role::role == 'master'
    $read_only = $is_master ? {
        true  => 0,
        false => 1,
    }

    profile::mariadb::section { $shard: }

    include ::profile::standard
    include ::passwords::misc::scripts
    include ::profile::base::firewall
    ::profile::mariadb::ferm { 'misc': }
    # hack until m5 servers are bought and proxy is in use
    if $shard == 'm5' {
        include ::profile::mariadb::ferm_wmcs
    }
    include ::profile::mariadb::monitor::prometheus

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    include mariadb::service

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/misc.my.cnf.erb',
        basedir   => $profile::mariadb::packages_wmf::basedir,
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        ssl       => 'puppet-cert',
        read_only => $read_only,
        p_s       => 'on',
    }

    class { 'profile::mariadb::grants::production':
        shard    => $shard,
        prompt   => "MISC ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $is_master,
    }
    class { 'mariadb::monitor_disk':
        is_critical   => $is_master,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        is_critical   => $is_master,
        contact_group => 'admins',
    }
    mariadb::monitor_readonly { [ $shard ]:
        read_only     => $read_only,
        is_critical   => false,
        contact_group => 'admins',
    }
    mariadb::monitor_replication { [ $shard ]:
        is_critical   => false,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_memory': }
}

