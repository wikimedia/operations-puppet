# == Class role::cassandra
#
class role::cassandra {
    sysctl::parameters { 'cassandra':
        values => {
            'vm.max_map_count' => 1048575,
        },
    }

    # Parameters to be set by Hiera
    class { '::cassandra': }
}
