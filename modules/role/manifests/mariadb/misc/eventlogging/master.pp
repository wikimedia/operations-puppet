class role::mariadb::misc::eventlogging::master {
    include ::standard
    include ::profile::base::firewall
    include ::profile::mariadb::ferm
    include ::profile::mariadb::monitor

    include ::profile::mariadb::misc::eventlogging::database
    system::role { 'role::mariadb::misc::eventlogging::master':
        description => 'Eventlogging Master datastore',
    }
}
