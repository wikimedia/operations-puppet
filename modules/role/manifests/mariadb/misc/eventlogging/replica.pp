class role::mariadb::misc::eventlogging::replica {

    include ::profile::standard
    include ::profile::base::firewall
    ::profile::mariadb::ferm { 'eventlogging_replica': }
    include ::profile::mariadb::monitor

    include ::profile::mariadb::misc::eventlogging::database
    # custom manual replication setup
    include ::profile::mariadb::misc::eventlogging::replication
    # custom data sanitization setup to apply the Analytics
    # data retention policies
    include ::profile::mariadb::misc::eventlogging::sanitization

    system::role { 'role::mariadb::misc::eventlogging::replica':
        description => 'Eventlogging Datastore Custom Replica',
    }
}
