class role::mariadb::misc::eventlogging::replica {

    include ::profile::standard
    include ::profile::base::firewall
    ::profile::mariadb::ferm { 'eventlogging_replica': }
    include ::profile::mariadb::monitor

    include ::profile::mariadb::misc::eventlogging::database

    system::role { 'role::mariadb::misc::eventlogging::replica':
        description => 'Eventlogging Datastore Custom Replica',
    }
}
