# sanitarium role: it replicates from all core shards (except x1), and
# sanitizes most data on production on 1 instance, before the data arrives to
# labs.
#
# It is identical in function to the mariadb::sanitarium role, but it does
# it very differently (single instance, innodb instead of Tokudb, different
# hardware, etc. Eventually, this will substitute sanitarium and will be
# renamed, but for now, both have to coexist.

class role::mariadb::sanitarium2 {
    system::role { 'role::mariadb::sanitarium':
        description => 'Sanitarium DB Server',
    }

    include ::standard
    include passwords::misc::scripts
    include ::base::firewall
    include role::mariadb::ferm
    include role::labs::db::common
    include role::labs::db::check_private_data

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
    }

    class {'mariadb::packages_wmf':
        package => 'wmf-mariadb101',
    }

    class { 'mariadb::config':
        config => 'role/mariadb/mysqld_config/sanitarium2.my.cnf.erb',
        ssl    => 'puppet-cert',
    }

    class {'mariadb::service':
        package => 'wmf-mariadb101',
    }

    class { 'mariadb::monitor_disk':
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        contact_group => 'admins',

    file { '/usr/local/sbin/redact_sanitarium.sh':
        ensure  => file,
        source  => 'puppet:///modules/role/mariadb/redact_sanitarium.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        require => File['/etc/mysql/filtered_tables.txt'],
    }
}

