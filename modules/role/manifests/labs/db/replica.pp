class role::labs::db::replica {

    system::role { 'labs::db::replica':
        description => 'Labs replica database',
    }

    include ::standard
    class { '::mariadb::packages_wmf': }
    class { '::mariadb::service': }
    include ::profile::mariadb::monitor
    include ::profile::base::firewall

    ferm::service{ 'mariadb_labs_db_replica':
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

    include ::passwords::misc::scripts

    include ::role::labs::db::common
    include ::role::labs::db::views
    include ::role::labs::db::check_private_data

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        mysql_shard => 'multi',
        socket      => '/run/mysqld/mysqld.sock',
    }

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/labsdb-replica.my.cnf.erb',
        basedir       => '/opt/wmf-mariadb101',
        datadir       => '/srv/sqldata',
        socket        => '/run/mysqld/mysqld.sock',
        tmpdir        => '/srv/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

}
