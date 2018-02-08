class role::mariadb::core_multiinstance {
    system::role { 'mariadb::core':
        description => 'Core multi-instance server',
    }
    include ::profile::base::firewall
    include ::standard

    include ::profile::mariadb::core::multiinstance
}
