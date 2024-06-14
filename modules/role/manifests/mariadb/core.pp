class role::mariadb::core {
    include profile::base::production
    include profile::firewall
    include role::mariadb::ferm
    include profile::mariadb::core
}
