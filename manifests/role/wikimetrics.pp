# == Class role::wikimetrics
# This is the production wikimetrics role
class role::wikimetrics {
    include ::wikimetrics::base

    class { '::wikimetrics::web':
        workers => 4,
    }

    class { '::wikimetrics::redis':
        queue_maxmemory => '1Gb',
    }

    class { '::wikimetrics::queue':
        require => Class['::wikimetrics::redis']
    }

    class { '::wikimetrics::scheduler':
        require => Class['::wikimetrics::redis']
    }
}

# == Class role::wikimetrics::staging
# This is the staging specific wikimetrics role
class role::wikimetrics::staging {
    include ::wikimetrics::base
    include ::wikimetrics::db

    class { '::wikimetrics::web':
        workers => 1,
    }

    class { '::wikimetrics::redis':
        queue_maxmemory => '1Gb',
    }

    class { '::wikimetrics::queue':
        require => Class['::wikimetrics::redis']
    }

    class { '::wikimetrics::scheduler':
        require => Class['::wikimetrics::redis']
    }
}
