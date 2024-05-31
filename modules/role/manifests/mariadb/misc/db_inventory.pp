class role::mariadb::misc::db_inventory {
    include profile::base::production
    include profile::firewall

    include profile::mariadb::misc::db_inventory
}
