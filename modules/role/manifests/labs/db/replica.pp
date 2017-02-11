class role::labs::db::replica {

    system::role { 'role::labs::db::replica':
        description => 'Labs replica database',
    }

    include standard
    class { 'mariadb::packages_wmf':
        package => 'wmf-mariadb101',
    }
    class { 'mariadb::service':
        package => 'wmf-mariadb101',
    }
    include role::mariadb::monitor
    include ::base::firewall

    ferm::service{ 'mariadb_internal':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => "(@resolve((db1011.eqiad.wmnet)) \
@resolve((neodymium.eqiad.wmnet)) @resolve((sarin.codfw.wmnet)) \
@resolve((dbproxy1010.eqiad.wmnet)) @resolve((dbproxy1011.eqiad.wmnet)) \
@resolve((labstore1004.eqiad.wmnet)) @resolve((labstore1005.eqiad.wmnet)))",
    }
    ferm::rule { 'mariadb_dba':
        rule => 'saddr @resolve((db1011.eqiad.wmnet)) proto tcp dport (3307) ACCEPT;',
    }

    include passwords::misc::scripts

    include role::labs::db::common
    include role::labs::db::views
    include role::labs::db::check_private_data

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        mysql_shard => 'multi',
    }

    class { 'mariadb::config':
        config        => 'mariadb/labsdb-replica.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

}
