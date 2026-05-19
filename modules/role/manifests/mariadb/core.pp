class role::mariadb::core {
    include profile::base::production
    include profile::firewall
    include profile::mariadb::core
}
