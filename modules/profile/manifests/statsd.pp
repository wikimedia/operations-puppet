# == Class: role::statsd
#
# Provisions a statsd-proxy instance that listens for StatsD metrics
# on UDP port 8125 and forwards to backends on UDP ports 8126+,
# as well as the set of statsite backends that listen on these ports.
#
class profile::statsd (
    Stdlib::Host   $graphite_host = lookup('graphite_host'),
){

    class { '::statsd_proxy':
        server_port   => 8125,
        backend_ports => range(8126, 8131),
    }

    # load balancer frontend, backend ports 8126-8131 are only accessed from localhost
    ferm::service { 'statsd':
        proto   => 'udp',
        port    => '8125',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

    class { '::statsite': }

    # statsite backends
    statsite::instance { '8126':
        port          => 8126,
        graphite_host => $graphite_host,
        input_counter => "statsd.${::hostname}-8126.received",
    }

    statsite::instance { '8127':
        port          => 8127,
        graphite_host => $graphite_host,
        input_counter => "statsd.${::hostname}-8127.received",
    }

    statsite::instance { '8128':
        port          => 8128,
        graphite_host => $graphite_host,
        input_counter => "statsd.${::hostname}-8128.received",
    }

    statsite::instance { '8129':
        port          => 8129,
        graphite_host => $graphite_host,
        input_counter => "statsd.${::hostname}-8129.received",
    }

    statsite::instance { '8130':
        port          => 8130,
        graphite_host => $graphite_host,
        input_counter => "statsd.${::hostname}-8130.received",
    }

    statsite::instance { '8131':
        port          => 8131,
        graphite_host => $graphite_host,
        input_counter => "statsd.${::hostname}-8131.received",
    }
}
