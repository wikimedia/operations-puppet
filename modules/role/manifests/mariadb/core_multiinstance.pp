class role::mariadb::core_multiinstance {
    include profile::firewall
    include profile::base::production

    include profile::mariadb::core::multiinstance
}
