# == Class role::wikimetrics::production
# This is the production wikimetrics role
class role::wikimetrics::production {
    include ::wikimetrics::base

    # Production wikimetrics instance (in labs) needs a mysql client
    # to access labsdb
    require_package('mysql-client')

    class { '::wikimetrics::web':
        workers => 4,
    }

    class { '::wikimetrics::redis':
        queue_maxmemory => '1Gb',
    }

    class { '::wikimetrics::queue':
        require => Class['::wikimetrics::redis'],
    }

    class { '::wikimetrics::scheduler':
        require => Class['::wikimetrics::redis'],
    }
}

