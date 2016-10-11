# parsercache (pc) specific configuration
class role::mariadb::parsercache(
    $shard,
    ) {

    include standard

    include role::mariadb::monitor
    include role::mariadb::ferm
    include passwords::misc::scripts
    class { 'role::mariadb::groups':
        mysql_group => 'parsercache',
        mysql_shard => $shard,
        mysql_role  => 'master',
    }

    system::role { 'role::mariadb::parsercache':
        description => "Parser Cache Database ${shard}",
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    include role::mariadb::grants::core
    class { 'role::mariadb::grants::production':
        shard    => 'parsercache',
        prompt   => 'PARSERCACHE',
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::config':
        config  => 'mariadb/parsercache.my.cnf.erb',
        datadir => '/srv/sqldata-cache',
        tmpdir  => '/srv/tmp',
        ssl     => 'on',
        p_s     => 'off',
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => true,
    }

    # mysql monitoring access from tendril (db1011)
    ferm::rule { 'mysql_tendril':
        rule => 'saddr 10.64.0.15 proto tcp dport (3306) ACCEPT;',
    }
}

