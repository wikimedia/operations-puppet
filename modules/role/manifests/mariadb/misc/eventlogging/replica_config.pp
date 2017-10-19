class role::mariadb::misc::eventlogging::replica_config {
    include ::profile::mariadb::misc::eventlogging::replication

    system::role { 'role::mariadb::misc::eventlogging::replica_config':
        description => 'Eventlogging Datastore Custom Replica',
    }
}