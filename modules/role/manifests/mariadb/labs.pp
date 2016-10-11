# MariaDB 10 labsdb multiple-shards slave.
# This role is deprecated but still in use
# It should be migrated to labs::db::slave
class role::mariadb::labs {

    system::role { 'role::mariadb::labs':
        description => 'Labs DB Slave',
    }

    include standard
    include role::mariadb::monitor
    include passwords::misc::scripts
    include role::mariadb::ferm
    include base::firewall

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        config  => 'mariadb/labs.my.cnf.erb',
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

