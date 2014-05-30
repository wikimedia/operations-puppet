# == Class: role::rcstream
#
# Provisions a recent changes -> redis -> socket.io -> Nginx setup
# that streams recent changes from MediaWiki to users via socket.io,
# a convenience layer over the WebSockets protocol.
#
class role::rcstream {
    if versioncmp($::lsbdistrelease, '14.04') < 0 {
        fail('requires 14.04+')
    }

    class { '::redis':
        maxmemory         => '100mb',
        dir               => '/var/run/redis',
        persist           => false,
        redis_replication => false,
    }

    # Spawn as many instances as there are CPU cores, less two.
    $backends = range(10080, 10080 + $::processorcount - 2)

    class { '::rcstream':
        redis        => 'redis://127.0.0.1:6379',
        bind_address => '127.0.0.1',
        ports        => $backends,
    }

    class { '::rcstream::proxy':
        backends => $backends,
    }

    nrpe::monitor_service { 'rcstream_backend':
        description  => 'Recent Changes Stream Python backend',
        nrpe_command => '/usr/local/sbin/rcstreamctl check',
        require      => Service['rcstream'],
    }
}
