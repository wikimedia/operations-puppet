class role::mariadb::core_test {

    system::role { 'mariadb::core':
        description => 'Core Test DB Server',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::mariadb::monitor
    include ::passwords::misc::scripts
    include ::role::mariadb::ferm
    require ::profile::mariadb::packages_wmf
    include ::profile::mariadb::wmfmariadbpy
    include ::profile::mariadb::core_test
}
