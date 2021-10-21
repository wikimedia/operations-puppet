class role::mariadb::dbstore_multiinstance {
    system::role { 'mariadb::dbstore_multiinstance':
        description => 'DBStore multi-instance server',
    }

    include ::profile::base::production
    include ::profile::base::firewall

    include ::profile::mariadb::dbstore_multiinstance
}
