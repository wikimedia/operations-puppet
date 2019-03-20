# == Class confluent::kafka::broker::alerts
# Sets up common alerts for a Kafka broker.
#
# == Parameters
#
# [*nagios_servicegroup*]
#   Nagios Service group to use for alerts.  Default: undef
#
# [*replica_maxlag_warning*]
#   Warning threshold for MaxLag alerts.  Default 1000
#
#  [*replica_maxlag_critical*]
#   Critical threshold for MaxLag alerts.  Default: 10000
#
class confluent::kafka::broker::alerts(
    $nagios_servicegroup     = undef,
    $replica_maxlag_warning  = '1000',
    $replica_maxlag_critical = '10000',
    $nrpe_contact_group      = 'admins'
) {
    require ::confluent::kafka::broker
    require ::confluent::kafka::broker::jmxtrans

    $jmx_port     = $::confluent::kafka::broker::jmx_port
    $group_prefix = $::confluent::kafka::broker::jmxtrans::group_prefix

    # Generate icinga alert if Kafka Server is not running.
    nrpe::monitor_service { 'kafka':
        description   => 'Kafka Broker Server',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "Kafka /etc/kafka/server.properties"',
        contact_group => $nrpe_contact_group,
        critical      => true,
    }

    # jmxtrans statsd writer emits fqdns in keys
    # by substituting '.' with '_' and suffixing the jmx port.
    $graphite_broker_key = regsubst("${::fqdn}_${jmx_port}", '\.', '_', 'G')

    # Alert if any Kafka has under replicated partitions.
    # If it does, this means a broker replica is falling behind
    # and will be removed from the ISR.
    monitoring::graphite_threshold { 'kafka-broker-UnderReplicatedPartitions':
        description     => 'Kafka Broker Under Replicated Partitions',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000523/kafka-graphite?refresh=5m&panelId=29&fullscreen&orgId=1'],
        metric          => "${group_prefix}kafka.${graphite_broker_key}.kafka.server.ReplicaManager.UnderReplicatedPartitions.Value",
        warning         => '1',
        critical        => '10',
        # Alert if any undereplicated for more than 50%
        # of the time in the last 30 minutes.
        from            => '30min',
        percentage      => 50,
        group           => $nagios_servicegroup,
    }

    # Alert if any Kafka Broker replica lag is too high
    monitoring::graphite_threshold { 'kafka-broker-Replica-MaxLag':
        description     => 'Kafka Broker Replica Max Lag',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000523/kafka-graphite?refresh=5m&panelId=16&fullscreen&orgId=1'],
        metric          => "${group_prefix}kafka.${graphite_broker_key}.kafka.server.ReplicaFetcherManager.MaxLag.Value",
        warning         => $replica_maxlag_warning,
        critical        => $replica_maxlag_critical,
        # Alert if large replica lag for more than 50%
        # of the time in the last 30 minutes.
        from            => '30min',
        percentage      => 50,
        group           => $nagios_servicegroup,
    }
}
