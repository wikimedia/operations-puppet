# SPDX-License-Identifier: Apache-2.0
# == define profile::kafka::burrow
#
# Consumer offset lag monitoring tool template for a generic Kafka cluster.
# Compatible only with burrow >= 1.0.
#
define profile::kafka::burrow(
    $monitoring_config,
) {
    $config = kafka_config($title)
    $smtp_server = 'localhost'
    $kafka_cluster_name = $config['name']

    $alert_whitelist = $monitoring_config[$title]['alert_whitelist']
    $burrow_http_port = $monitoring_config[$title]['burrow_port']
    $prometheus_burrow_http_port = $monitoring_config[$title]['burrow_exporter_port']
    $to_email = $monitoring_config[$title]['to_email']

    burrow { $title:
        zookeeper_hosts    => $config['zookeeper']['hosts'],
        zookeeper_path     => $config['zookeeper']['chroot'],
        kafka_cluster_name => $kafka_cluster_name,
        kafka_brokers      => $config['brokers']['array'],
        smtp_server        => $smtp_server,
        from_email         => 'Burrow <noreply@wikimedia.org>',
        to_email           => $to_email,
        lagcheck_intervals => 100,
        httpserver_port    => $burrow_http_port,
        alert_whitelist    => $alert_whitelist,
    }

    profile::prometheus::burrow_exporter { $title:
        burrow_addr => "localhost:${burrow_http_port}",
        port        => $prometheus_burrow_http_port,
    }

    profile::auto_restarts::service { "burrow-${title}": }

    # Burrow offers a HTTP REST API
    ferm::service { "burrow-${title}":
        proto  => 'tcp',
        port   => $burrow_http_port,
        srange => '$DOMAIN_NETWORKS',
    }
}
