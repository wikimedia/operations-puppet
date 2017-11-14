class role::mariadb::misc::eventlogging::replica {

    include ::standard
    include ::profile::base::firewall
    include ::profile::mariadb::ferm
    include ::profile::mariadb::monitor

    include ::profile::mariadb::misc::eventlogging::database
    include ::profile::mariadb::misc::eventlogging::replication

    system::role { 'role::mariadb::misc::eventlogging::replica':
        description => 'Eventlogging Datastore Custom Replica',
    }
}
