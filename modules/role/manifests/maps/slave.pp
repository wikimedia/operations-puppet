# Sets up a maps server slave
class role::maps::slave {
    include ::role::maps::server
    include ::postgresql::slave
    include ::role::maps::postgresql_common

    system::role { 'role::maps::slave':
        ensure      => 'present',
        description => 'Maps Postgres slave',
    }
}

