# == Class: role::editstream
#
# Provisions a recent changes -> redis -> socket.io -> Nginx setup
# that streams recent changes from MediaWiki to users via socket.io,
# a convenience layer over the WebSockets protocol.
#
class role::editstream {

    if versioncmp($::lsbdistrelease, '14.04') < 0 {
        fail('requires 14.04+')
    }

    class { '::redis':
        maxmemory         => '1Gb',
        dir               => '/var/run/redis',
        persist           => false,
        redis_replication => false,
    }

    $backends = [ 10080, 10081, 10082 ]

    class { '::editstream':
        iface => '127.0.0.1',
        ports => $backends,
    }

    class { '::editstream::proxy':
        backends => $backends,
    }
}
