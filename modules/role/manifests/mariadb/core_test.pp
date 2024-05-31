class role::mariadb::core_test {
    include profile::base::production
    include profile::firewall
    include profile::mariadb::monitor
    include role::mariadb::ferm
    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    include profile::mariadb::core_test
}
