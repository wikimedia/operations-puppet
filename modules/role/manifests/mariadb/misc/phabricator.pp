# Phab pretty much requires its own sandbox
# strict sql_mode -- nice! but other services moan
# admin tool that needs non-trivial permissions
class role::mariadb::misc::phabricator(
    $ssl       = 'puppet-cert',
    $p_s       = 'on',
    ) {
    $shard = lookup('mariadb::shard')

    system::role { 'mariadb::misc':
        description => "Misc Services Database ${shard} (phabricator)",
    }

    include ::profile::standard
    include mariadb::packages_wmf
    include mariadb::service
    include profile::mariadb::mysql_role

    profile::mariadb::section { $shard: }

    include ::passwords::misc::scripts
    include ::profile::base::firewall
    ::profile::mariadb::ferm { 'phabricator': }

    include ::profile::mariadb::monitor::prometheus

    $is_master = $profile::mariadb::mysql_role::role == 'master'
    $read_only = $is_master ? {
        true  => 0,
        false => 1,
    }

    $stopwords_database = 'phabricator_search'

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/phabricator.my.cnf.erb',
        basedir   => '/opt/wmf-mariadb101', # FIXME: config should default to 10.1
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        sql_mode  => 'STRICT_ALL_TABLES',
        read_only => $read_only,
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
        is_critical   => $is_master,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        is_critical   => $is_master,
        contact_group => 'admins',
    }

    mariadb::monitor_replication { [ $shard ]:
        is_critical   => false,
        contact_group => 'admins',
        multisource   => false,
    }

    mariadb::monitor_readonly { [ $shard ]:
        read_only     => $read_only,
        is_critical   => false,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_memory': }
}

