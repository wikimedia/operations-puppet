class role::mariadb::misc::db_inventory {

    system::role { 'mariadb::db_inventory':
        description => 'zarcillo database server',
    }

    include profile::base::production
    include profile::base::firewall

    include profile::mariadb::misc::db_inventory
}
