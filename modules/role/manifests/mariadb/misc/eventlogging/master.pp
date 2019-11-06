class role::mariadb::misc::eventlogging::master {
    include ::profile::standard
    include ::profile::base::firewall
    ::profile::mariadb::ferm { 'eventlogging_master': }
    include ::profile::mariadb::monitor

    include ::profile::mariadb::misc::eventlogging::database

    system::role { 'role::mariadb::misc::eventlogging::master':
        description => 'Eventlogging Master datastore',
    }
}
