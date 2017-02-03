# == Class role::wikimetrics::staging
# This is the staging specific wikimetrics role
#
# filtertags: labs-project-wikimetrics
class role::wikimetrics::staging {
    include ::wikimetrics::base

    # The mysql server is only included in staging role
    # This is because we are setting up local databases in staging for
    # testing purposes but using the labsdb for the production role.
    # Labsdb gives us automatic backups and keeps our instance nfs free.
    class { '::mysql::server':
        config_hash => {
            'datadir'      => '/srv/mysql',
            'bind_address' => '127.0.0.1',
        },
    }

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
