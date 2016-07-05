class role::prometheus::ops {
    prometheus::server { 'ops':
        listen_address => '127.0.0.1:9900',
    }

    prometheus::web { 'ops':
        proxy_pass => 'http://localhost:9900/ops',
    }

    # Query puppet exported resources and generate a list of hosts for
    # prometheus to poll metrics from. Ganglia::Cluster is used to generate the
    # mapping from cluster to a list of its members.
    file { "/srv/prometheus/ops/targets/node_site_${::site}.yaml":
        content => generate('/usr/local/bin/prometheus-ganglia-gen',
                            "--site=${::site}"),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
