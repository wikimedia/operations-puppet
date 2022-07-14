# parsercache (pc) specific configuration
# These are mariadb servers acting as on-disk cache for parsed wikitext

class profile::mariadb::parsercache (
    $shard = lookup('mariadb::parsercache::shard'),
    $wikiuser_username = lookup('profile::mariadb::wikiuser_username'),
    String $sync_binlog = lookup('profile::mariadb::config::sync_binlog', {'default_value' => '0'}),
    String $flush_log_at_trx_commit = lookup('profile::mariadb::config::innodb_flush_log_at_trx_commit', {'default_value' => '0'})
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

    profile::mariadb::grants::core { $shard:
        wikiadmin_pass    => $passwords::misc::scripts::wikiadmin_pass,
        wikiuser_username => $wikiuser_username,
        wikiuser_pass     => $passwords::misc::scripts::wikiuser_pass,
    }
    class { 'profile::mariadb::grants::production':
        shard    => 'parsercache',
        prompt   => 'PARSERCACHE',
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::config':
        config                  => 'role/mariadb/mysqld_config/parsercache.my.cnf.erb',
        datadir                 => '/srv/sqldata-cache',
        tmpdir                  => '/srv/tmp',
        ssl                     => 'puppet-cert',
        p_s                     => 'on',
        basedir                 => $profile::mariadb::packages_wmf::basedir,
        sync_binlog             => $sync_binlog,
        flush_log_at_trx_commit => $flush_log_at_trx_commit,
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

    mariadb::monitor_eventscheduler { [ $shard ]:
        is_critical => false,
    }

    mariadb::monitor_readonly { [ $shard ]:
        read_only   => false,
        # XXX(kormat): Deliberately using $is_primary_master here rather than $is_master,
        # the inactive DC being read-only isn't a page-worthy event.
        is_critical => $is_primary_master,
    }

    if profile::mariadb::section_params::is_repl_client($shard, $mysql_role) {
        $source_dc = profile::mariadb::section_params::get_repl_src_dc($mysql_role)
        mariadb::monitor_replication { $shard:
            source_dc   => $source_dc,
        }
        # XXX(kormat): Disable this for now, it's incredibly spammy.
        # profile::mariadb::replication_lag { $shard: }
    }

    class { 'mariadb::monitor_memory': }
}
