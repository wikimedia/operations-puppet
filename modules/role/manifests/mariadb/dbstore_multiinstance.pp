class role::mariadb::dbstore_multiinstance {
    system::role { 'mariadb::core':
        description => 'DBStore multi-instance server',
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::mariadb::dbstore_multiinstance
}
