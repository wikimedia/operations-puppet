# Sets up a maps server slave
class role::maps::slave {
    include ::postgresql::slave

    system::role { 'role::maps::slave':
        ensure      => 'present',
        description => 'Maps Postgres slave',
    }
}

