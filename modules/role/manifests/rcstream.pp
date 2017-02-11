# == Class: role::rcstream
#
# Provisions a recent changes -> redis -> socket.io -> Nginx setup
# that streams recent changes from MediaWiki to users via socket.io,
# a convenience layer over the WebSockets protocol.
#
# filtertags: labs-project-deployment-prep
class role::rcstream {
    include ::standard

    system::role { 'role::rcstream':
        description => 'MediaWiki Recent Changes stream',
    }

    redis::instance { 6379:
        settings => {
            maxmemory                   => '100mb',
            maxmemory_policy            => 'volatile-lru',
            maxmemory_samples           => '5',
            no_appendfsync_on_rewrite   => 'yes',
            save                        => '""',
            slave_read_only             => 'no',
            stop_writes_on_bgsave_error => 'no',
            tcp_keepalive               => 0,
            auto_aof_rewrite_min_size   => '512mb',
            bind                        => '0.0.0.0',
            client_output_buffer_limit  => 'slave 512mb 200mb 60',
        },
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

    diamond::collector::nginx { 'rcstream': }

    ferm::service { 'rcstream':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'rcstream_redis':
        proto  => 'tcp',
        port   => '6379',
        srange => '$DOMAIN_NETWORKS',
    }

    diamond::collector { 'RCStream':
        source   => 'puppet:///modules/rcstream/diamond_collector.py',
        settings => {
            backends => $backends,
        },
    }
}
