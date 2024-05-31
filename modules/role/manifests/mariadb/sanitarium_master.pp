class role::mariadb::sanitarium_master {
    include profile::base::production
    include profile::firewall
    include role::mariadb::ferm
    include profile::mariadb::core
}
