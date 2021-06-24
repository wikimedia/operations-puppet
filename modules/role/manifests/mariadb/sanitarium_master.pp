class role::mariadb::sanitarium_master {
    system::role { 'mariadb::core':
        description => 'Core DB Server (Sanitarium master)',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::role::mariadb::ferm
    include ::profile::mariadb::core
}
