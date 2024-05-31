class role::mariadb::analytics_replica {
    include profile::base::production
    include profile::firewall

    include profile::mariadb::dbstore_multiinstance
}
