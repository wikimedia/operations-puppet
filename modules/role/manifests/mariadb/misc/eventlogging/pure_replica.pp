class role::mariadb::misc::eventlogging::pure_replica {
    include ::profile::mariadb::misc::eventlogging::replication

    system::role { 'role::mariadb::misc::eventlogging::pure_replica':
        description => 'Eventlogging Datastore Custom Replica',
    }
}