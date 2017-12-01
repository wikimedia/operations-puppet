# sanitarium_multisource role: it replicates from all core shards
# (except x1), and sanitizes most data on production on 1 instance, before
# the data arrives to labs.
#
# It is identical in function to the mariadb::sanitarium role, but it does
# it very differently (single instance, innodb instead of Tokudb, different
# hardware, using multi-source replication). This is going to be deprecated
# by the similar, but easier to handle sanitarium_multiinstance. But for
# now, both have to coexist.

class role::mariadb::sanitarium_multisource {
    system::role { 'mariadb::sanitarium':
        description => 'Sanitarium DB Server',
    }

    include ::standard
    include passwords::misc::scripts
    include ::profile::base::firewall
    include role::mariadb::ferm
    include role::labs::db::common
    include role::labs::db::check_private_data

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        socket      => '/run/mysqld/mysqld.sock',
    }

    class {'mariadb::packages_wmf': }
    class {'mariadb::service': }

    class { 'mariadb::config':
        basedir       => '/opt/wmf-mariadb101',
        socket        => '/run/mysqld/mysqld.sock',
        config        => 'role/mariadb/mysqld_config/sanitarium_multisource.my.cnf.erb',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

    class { 'mariadb::monitor_disk':
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        contact_group => 'admins',
    }

}
