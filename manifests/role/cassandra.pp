# == Class role::cassandra
#
class role::cassandra {
    # Parameters to be set by Hiera
    class { '::cassandra': }

    system::role { 'role::cassandra':
        description => 'Cassandra server',
    }
}
