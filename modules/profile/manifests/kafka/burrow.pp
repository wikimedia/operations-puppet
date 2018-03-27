# == define profile::kafka::burrow
#
# Consumer offset lag monitoring tool template for a generic Kafka cluster
#
define profile::kafka::burrow(
    $prometheus_nodes,
    $monitoring_config,
) {
    $config = kafka_config($title)
    $smtp_server = 'mx1001.wikimedia.org'
    $kafka_cluster_name = $config['name']

    $consumer_groups = $monitoring_config[$title]['consumer_groups']
    $burrow_http_port = $monitoring_config[$title]['burrow_port']
    $prometheus_burrow_http_port = $monitoring_config[$title]['burrow_exporter_port']
    $to_emails = $monitoring_config[$title]['to_emails']

    burrow { $title:
        zookeeper_hosts    => $config['zookeeper']['hosts'],
        zookeeper_path     => $config['zookeeper']['chroot'],
        kafka_cluster_name => $kafka_cluster_name,
        kafka_brokers      => $config['brokers']['array'],
        smtp_server        => $smtp_server,
        from_email         => "burrow@${::fqdn}",
        to_emails          => $to_emails,
        lagcheck_intervals => 100,
        httpserver_port    => $burrow_http_port,
        consumer_groups    => $consumer_groups,
    }

    profile::prometheus::burrow_exporter { $title:
        burrow_addr      => "localhost:${burrow_http_port}",
        port             => $prometheus_burrow_http_port,
        prometheus_nodes => $prometheus_nodes,
    }

    # Burrow offers a HTTP REST API
    ferm::service { "burrow-${title}":
        proto  => 'tcp',
        port   => $burrow_http_port,
        srange => '$DOMAIN_NETWORKS',
    }

    # If nagios_check is set for this burrow instance monitoring_config,
    # declare burrow::check_consumer_lag for each configured consumer group.
    # This will set up an icinga alert if any of the configure groups
    # start laggign.
    if has_key($monitoring_config[$title], 'nagios_check') {
        # We might want to only use icinga to monitor specific consumer groups.
        # If these are given in the nagios_check config, then use them instead
        # of the consumer_groups that burrow itself is monitoring.
        $check_consumer_groups = $monitoring_config[$title]['consumer_groups'] ? {
            undef   => $consumer_groups,
            default => $monitoring_config[$title]['consumer_groups'],
        }
        $lag_threshold = $monitoring_config[$title]['nagios_check']['lag_threshold'] ? {
            undef   => 1000,
            default => $monitoring_config[$title]['nagios_check']['lag_threshold'],
        }
        # Pull any other burrow::check_consumer_lag parameter overides from the
        # nagios_check hash in monitoring config for this kafka cluster.
        $contact_group = $monitoring_config[$title]['nagios_check']['contact_group'] ? {
            undef   => 'admins',
            default => $monitoring_config[$title]['nagios_check']['contact_group'],
        }
        $critical = $monitoring_config[$title]['nagios_check']['critical'] ? {
            undef   => false,
            default => $monitoring_config[$title]['nagios_check']['critical'],
        }

        # Set up monitoring of configured consumer group lag via icinga.
        burrow::check_consumer_lag { $check_consumer_groups:
            kafka_cluster_name => $kafka_cluster_name,
            burrow_uri         => "http://localhost:${burrow_http_port}",
            lag_threshold      => $lag_threshold,
            contact_group      => $contact_group,
            critical           => $critical,
        }
    }
}
