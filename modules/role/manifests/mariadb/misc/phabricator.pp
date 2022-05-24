# Phab pretty much requires its own sandbox
# strict sql_mode -- nice! but other services moan
# admin tool that needs non-trivial permissions
class role::mariadb::misc::phabricator(
    $ssl       = 'puppet-cert',
    $p_s       = 'on',
    ) {
    $shard = lookup('mariadb::shard')

    system::role { 'mariadb::misc::phabricator':
        description => "Misc Services Database ${shard} (phabricator)",
    }

    include ::profile::base::production
    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    include mariadb::service
    include profile::mariadb::mysql_role

    profile::mariadb::section { $shard: }

    include ::passwords::misc::scripts
    include ::profile::base::firewall
    ::profile::mariadb::ferm { 'phabricator': }

    include ::profile::mariadb::monitor::prometheus

    $mysql_role = $profile::mariadb::mysql_role::role
    $is_master = $mysql_role == 'master'
    $read_only = profile::mariadb::section_params::is_read_only($shard, $mysql_role)
    $is_writeable_dc = profile::mariadb::section_params::is_writeable_dc($shard)
    $is_primary_master = $is_master and $is_writeable_dc

    $stopwords_database = 'phabricator_search'

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/phabricator.my.cnf.erb',
        basedir   => $profile::mariadb::packages_wmf::basedir,
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        sql_mode  => 'STRICT_ALL_TABLES',
        read_only => Integer($read_only),
        ssl       => $ssl,
        p_s       => $p_s,
    }

    file { '/etc/mysql/phabricator-stopwords.txt':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('role/phabricator/stopwords.txt.erb'),
    }

    file { '/etc/mysql/phabricator-stopwords-update.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('role/phabricator/stopwords-update.sql.erb'),
    }

    file { '/etc/mysql/phabricator-init.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('role/phabricator/init.sql.erb'),
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
        is_critical   => $is_primary_master,
    }

    class { 'mariadb::monitor_process':
        is_critical   => $is_primary_master,
    }

    if profile::mariadb::section_params::is_repl_client($shard, $mysql_role) {
        $source_dc = profile::mariadb::section_params::get_repl_src_dc($mysql_role)
        mariadb::monitor_replication { [ $shard ]:
            is_critical => false,
            source_dc   => $source_dc,
        }
        profile::mariadb::replication_lag { $shard: }
    }

    mariadb::monitor_readonly { $shard:
        read_only   => $read_only,
        # XXX(kormat): Not using $is_primary_master, as we want to alert even for an inactive DC.
        is_critical => $is_master,
    }

    class { 'mariadb::monitor_memory': }
}

