# parsercache (pc) specific configuration
# These are mariadb servers acting as on-disk cache for parsed wikitext

class profile::mariadb::parsercache (
    $shard = lookup('mariadb::parsercache::shard')
    ){
    $mw_primary = mediawiki::state('primary_dc')

    include ::profile::mariadb::mysql_role
    profile::mariadb::section { $shard: }

    include ::passwords::misc::scripts
    include ::profile::mariadb::monitor::prometheus

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    class { 'mariadb::service': }

    include ::profile::mariadb::grants::core
    class { 'profile::mariadb::grants::production':
        shard    => 'parsercache',
        prompt   => 'PARSERCACHE',
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/parsercache.my.cnf.erb',
        datadir => '/srv/sqldata-cache',
        tmpdir  => '/srv/tmp',
        ssl     => 'puppet-cert',
        p_s     => 'on',
        basedir => $profile::mariadb::packages_wmf::basedir,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => true,
    }
    $is_on_primary_dc = ($mw_primary == $::site)
    $contact_group = 'admins'

    class { 'mariadb::monitor_disk':
        is_critical   => $is_on_primary_dc,
        contact_group => $contact_group,
    }

    class { 'mariadb::monitor_process':
        is_critical   => $is_on_primary_dc,
        contact_group => $contact_group,
    }

    mariadb::monitor_readonly { [ $shard ]:
        read_only     => false,
        is_critical   => $is_on_primary_dc,
        contact_group => $contact_group,
    }

    mariadb::monitor_replication { [ $shard ]:
      multisource   => false,
      is_critical   => $is_on_primary_dc,
      contact_group => $contact_group,
      socket        => '/run/mysqld/mysqld.sock',
    }

    class { 'mariadb::monitor_memory': }
}
