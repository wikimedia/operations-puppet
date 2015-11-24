# == Class: role::rcstream
#
# Provisions a recent changes -> redis -> socket.io -> Nginx setup
# that streams recent changes from MediaWiki to users via socket.io,
# a convenience layer over the WebSockets protocol.
#
class role::rcstream {
    include standard

    system::role { 'role::rcstream':
        description => 'MediaWiki Recent Changes stream',
    }

    redis::instance { 6379:
        settings => { maxmemory => '100mb' },
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

    class { '::rcstream::proxy::ssl':
        backends => $backends,
    }

    if hiera('has_lvs', true) {
        include lvs::configuration
        class { 'lvs::realserver':
            realserver_ips => $lvs::configuration::service_ips['stream'][$::site],
        }
    }

    nrpe::monitor_service { 'rcstream_backend':
        description  => 'Recent Changes Stream Python backend',
        nrpe_command => '/usr/local/sbin/rcstreamctl check',
        require      => Service['rcstream'],
    }

    diamond::collector::nginx { 'rcstream': }

    ferm::service { 'rcstream':
        proto  => 'tcp',
        port   => '80',
        srange => '$INTERNAL',
    }

    ferm::service { 'rcstream_ssl':
        proto  => 'tcp',
        port   => '443',
        srange => '$INTERNAL',
    }

    ferm::service { 'rcstream_redis':
        proto  => 'tcp',
        port   => '6379',
        srange => '$INTERNAL',
    }

    monitoring::service { 'https_rcstream':
        description   => 'HTTPS',
        check_command => 'check_ssl_http!stream.wikimedia.org',
    }

    diamond::collector { 'RCStream':
        source   => 'puppet:///modules/rcstream/diamond_collector.py',
        settings => {
            backends => $backends,
        },
    }
}
