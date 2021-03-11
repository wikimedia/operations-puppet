# parsercache (pc) specific configuration
# These are mariadb servers acting as on-disk cache for parsed wikitext

class profile::mariadb::parsercache (
    $shard = lookup('mariadb::parsercache::shard')
) {
    $mw_primary = mediawiki::state('primary_dc')

    include ::profile::mariadb::mysql_role
    profile::mariadb::section { $shard: }

    $mysql_role = $profile::mariadb::mysql_role::role
    $is_master = $mysql_role == 'master'
    $is_writeable_dc = profile::mariadb::section_params::is_writeable_dc($shard)
    $is_primary_master = $is_master and $is_writeable_dc

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

    class { 'mariadb::monitor_disk':
        is_critical   => $is_primary_master,
    }

    class { 'mariadb::monitor_process':
        is_critical   => $is_primary_master,
    }

    mariadb::monitor_readonly { [ $shard ]:
        read_only   => false,
        is_critical => $is_primary_master,
    }

    if profile::mariadb::section_params::is_repl_client($shard, $mysql_role) {
        $source_dc = profile::mariadb::section_params::get_repl_src_dc($mysql_role)
        mariadb::monitor_replication { $shard:
            source_dc   => $source_dc,
        }
        profile::mariadb::replication_lag { $shard: }
    }

    class { 'mariadb::monitor_memory': }
}
