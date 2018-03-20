# parsercache (pc) specific configuration
# These are mariadb servers acting as on-disk cache for parsed wikitext

class role::mariadb::parsercache(
    $shard,
    ) {

    include ::standard
    include ::profile::base::firewall
    include ::profile::mariadb::monitor
    ::profile::mariadb::ferm { 'parsercache': }
    include ::passwords::misc::scripts
    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'parsercache',
        mysql_shard => $shard,
        mysql_role  => 'master',
    }

    system::role { 'mariadb::parsercache':
        description => "Parser Cache Database ${shard}",
    }

    include mariadb::packages_wmf
    include mariadb::service

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
        p_s     => 'off',
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => true,
    }

}
