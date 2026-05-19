class role::mariadb::sanitarium_master {
    include profile::base::production
    include profile::firewall
    include profile::mariadb::core
}
