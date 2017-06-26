# MariaDB 10 labsdb multiple-shards slave.
# This role is deprecated but still in use.
# Use role::labs::db::replica instead
class role::mariadb::labs_deprecated {

    system::role { 'mariadb::labs_deprecated':
        description => 'Labs DB Slave (deprecated role)',
    }

    include ::standard
    include role::mariadb::monitor
    include passwords::misc::scripts
    include role::mariadb::ferm
    include ::base::firewall
    include role::labs::db::common
    include role::labs::db::views
    include role::labs::db::check_private_data

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        socket      => '/tmp/mysql.sock',
    }

    include mariadb::packages_wmf
    include mariadb::service

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/labs.my.cnf.erb',
        datadir => '/srv/sqldata',
        tmpdir  => '/srv/tmp',
    }

    file { '/srv/innodb':
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    file { '/srv/tokudb':
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    # Required for TokuDB to start
    # See https://mariadb.com/kb/en/mariadb/enabling-tokudb/#check-for-transparent-hugepage-support-on-linux
    sysfs::parameters { 'disable-transparent-hugepages':
        values => {
            'kernel/mm/transparent_hugepage/enabled' => 'never',
            'kernel/mm/transparent_hugepage/defrag'  => 'never',
        }
    }
}

