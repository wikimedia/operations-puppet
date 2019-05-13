# == Class: role::statsd
#
# Provisions a statsd-proxy instance that listens for StatsD metrics
# on UDP port 8125 and forwards to backends on UDP ports 8126+,
# as well as the set of statsite backends that listen on these ports.
#
# filtertags: labs-project-graphite
class profile::statsd {

    class { '::statsd_proxy':
        server_port   => 8125,
        backend_ports => range(8126, 8131),
    }

    nrpe::monitor_service { 'statsd-proxy':
        description  => 'statsd-proxy process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C statsd-proxy',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Statsd',
    }

    # load balancer frontend, backend ports 8126-8131 are only accessed from localhost
    ferm::service { 'statsd':
        proto   => 'udp',
        port    => '8125',
        notrack => true,
        srange  => '$PRODUCTION_NETWORKS',
    }

    class { '::statsite': }

    # statsite backends
    statsite::instance { '8126':
        port          => 8126,
        input_counter => "statsd.${::hostname}-8126.received",
    }

    statsite::instance { '8127':
        port          => 8127,
        input_counter => "statsd.${::hostname}-8127.received",
    }

    statsite::instance { '8128':
        port          => 8128,
        input_counter => "statsd.${::hostname}-8128.received",
    }

    statsite::instance { '8129':
        port          => 8129,
        input_counter => "statsd.${::hostname}-8129.received",
    }

    statsite::instance { '8130':
        port          => 8130,
        input_counter => "statsd.${::hostname}-8130.received",
    }

    statsite::instance { '8131':
        port          => 8131,
        input_counter => "statsd.${::hostname}-8131.received",
    }

    $prometheus_labels = "{instance=~\"${::hostname}.*\"}"
    monitoring::check_prometheus { 'statsd_udp_inbound_errors':
        description     => 'statsd UDP receive errors are elevated',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/graphite-${::site}?orgId=1&refresh=1m&panelId=16&fullscreen"],
        query           => "scalar(100 * rate(node_netstat_Udp_InErrors${prometheus_labels}[5m]) / rate(node_netstat_Udp_InDatagrams${prometheus_labels}[5m]))",
        warning         => 1,
        critical        => 2,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    }
}
