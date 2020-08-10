# miscellaneous services clusters
class role::mariadb::misc(
    $shard  = 'm1',
    $master = false,
    ) {

    system::role { 'mariadb::misc':
        description => "Misc Services Database ${shard}",
    }

    $read_only = $master ? {
        true  => 0,
        false => 1,
    }

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    class { '::profile::mariadb::mysql_role':
        role => $mysql_role,
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

    include mariadb::packages_wmf
    include mariadb::service

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/misc.my.cnf.erb',
        basedir   => '/opt/wmf-mariadb101',
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
        enabled    => $master,
    }
    class { 'mariadb::monitor_disk':
        is_critical   => $master,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        is_critical   => $master,
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

