class role::mariadb::misc::eventlogging::replica {
    include ::profile::mariadb::misc::eventlogging::database
    include ::profile::mariadb::misc::eventlogging::replication

    system::role { 'role::mariadb::misc::eventlogging::replica':
        description => 'Eventlogging Datastore Custom Replica',
    }
}