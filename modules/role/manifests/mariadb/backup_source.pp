class role::mariadb::backup_source {
    include profile::base::production
    include profile::firewall

    include profile::mariadb::dbstore_multiinstance
}
