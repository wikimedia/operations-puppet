# == Class role::wikimetrics
#
class role::wikimetrics {
    include ::wikimetrics::base
    include ::wikimetrics::db
    include ::wikimetrics::web

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
