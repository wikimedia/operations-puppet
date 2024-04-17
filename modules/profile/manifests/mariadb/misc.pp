# miscellaneous services clusters
class profile::mariadb::misc (
    Profile::Mariadb::Valid_section $shard = lookup('mariadb::shard'),
) {
    require profile::mariadb::mysql_role
    require passwords::misc::scripts

    $mysql_role = $profile::mariadb::mysql_role::role
    $is_master = $mysql_role == 'master'
    $read_only = profile::mariadb::section_params::is_read_only($shard, $mysql_role)
    $is_writeable_dc = profile::mariadb::section_params::is_writeable_dc($shard)
    $is_primary_master = $is_master and $is_writeable_dc

    profile::mariadb::section { $shard: }

    ::profile::mariadb::ferm { 'misc': }
    include profile::mariadb::monitor::prometheus

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    include mariadb::service

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/misc.my.cnf.erb',
        basedir   => $profile::mariadb::packages_wmf::basedir,
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        ssl       => 'puppet-cert',
        read_only => Integer($read_only),
        p_s       => 'on',
    }

    class { 'profile::mariadb::grants::production':
        shard    => $shard,
        prompt   => "MISC ${shard}",
        password => $passwords::misc::scripts::mysql_cumin_pass,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $is_master,
    }
    class { 'mariadb::monitor_disk':
        is_critical   => $is_primary_master,
    }

    class { 'mariadb::monitor_process':
        is_critical   => $is_primary_master,
    }
    mariadb::monitor_readonly { $shard:
        read_only   => $read_only,
        # XXX(kormat): Not using $is_primary_master, as we want to alert even for an inactive DC.
        is_critical => $is_master,
    }
    if profile::mariadb::section_params::is_repl_client($shard, $mysql_role) {
        $source_dc = profile::mariadb::section_params::get_repl_src_dc($mysql_role)
        mariadb::monitor_replication { [ $shard ]:
            is_critical => false,
            source_dc   => $source_dc,
        }
    }

    class { 'mariadb::monitor_memory': }
}
