class role::mariadb::misc::eventlogging::master {
    include ::profile::mariadb::misc::eventlogging::database
    system::role { 'role::mariadb::misc::eventlogging::master':
        description => 'Eventlogging Master datastore',
    }
}