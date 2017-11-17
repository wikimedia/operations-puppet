# Phab pretty much requires its own sandbox
# strict sql_mode -- nice! but other services moan
# admin tool that needs non-trivial permissions
class role::mariadb::misc::phabricator(
    $shard     = 'm3',
    $master    = false,
    $snapshot  = false,
    $ssl       = 'puppet-cert',
    $p_s       = 'on',
    ) {

    system::role { 'mariadb::misc':
        description => "Misc Services Database ${shard} (phabricator)",
    }

    include ::standard
    include mariadb::packages_wmf
    include mariadb::service

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    include role::mariadb::monitor
    include passwords::misc::scripts
    include ::base::firewall
    include role::mariadb::ferm

    class { 'role::mariadb::groups':
        mysql_group => 'misc',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
        socket      => '/tmp/mysql.sock',
    }

    $read_only = $master ? {
        true  => 0,
        false => 1,
    }

    $stopwords_database = 'phabricator_search'

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/phabricator.my.cnf.erb',
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

    class { 'role::mariadb::grants::production':
        shard    => $shard,
        prompt   => "MISC ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $master,
        socket     => '/tmp/mysql.sock',
    }

    unless $master {
        mariadb::monitor_replication { [ $shard ]:
            is_critical   => false,
            contact_group => 'admins',
            multisource   => false,
            socket        => '/tmp/mysql.sock',
        }
    }
}

