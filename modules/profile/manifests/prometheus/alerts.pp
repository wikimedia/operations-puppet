# == Class: profile::prometheus::alerts
#
# Install icinga alerts based on Prometheus metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class profile::prometheus::alerts (
    Array[String] $datacenters = lookup('datacenters'),
) {

    # Monitor throughput and dropped messages on MirrorMaker instances.
    # main-eqiad -> jumbo MirrorMaker
    profile::kafka::mirror::alerts { 'main-eqiad_to_jumbo-eqiad':
        #  For now, alert analytics admins.  Change this back to admins soon.
        contact_group         => 'analytics',
        topic_blacklist       => '.*(change-prop|\.job\.|changeprop).*',
        prometheus_url        => 'http://prometheus.svc.eqiad.wmnet/ops',
        source_prometheus_url => 'http://prometheus.svc.eqiad.wmnet/ops',
    }

    # Cross DC main-eqiad <-> main-codfw MirrorMakers.
    profile::kafka::mirror::alerts { 'main-eqiad_to_main-codfw':
        prometheus_url        => 'http://prometheus.svc.codfw.wmnet/ops',
        source_prometheus_url => 'http://prometheus.svc.eqiad.wmnet/ops',
    }
    # main-eqiad is getting the bulk of the traffic from MediaWiki,
    # and it currently pulls msgs from main-codfw at a very low rate
    # (but we want to make sure that it doesn't drop to zero).
    profile::kafka::mirror::alerts { 'main-codfw_to_main-eqiad':
        #  For now, alert analytics admins, until alerts are more stable.
        prometheus_url        => 'http://prometheus.svc.eqiad.wmnet/ops',
        source_prometheus_url => 'http://prometheus.svc.codfw.wmnet/ops',
        warning_throughput    => 3,
    }


    # Eventlogging

    # Warn if p50 of overall error event throughput goes above 20 events/s
    # in a 15 minute period.
    # The EventError topic counted here includes both events that do not
    # validate and events that can not be processed for other reasons
    monitoring::check_prometheus { 'eventlogging_EventError_throughput':
        description     => 'Throughput of EventLogging EventError events',
        query           => 'scalar(quantile(0.50,sum(rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{cluster="kafka_jumbo",topic="eventlogging_EventError"}[15m]))))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
        warning         => 20,
        critical        => 30,
        method          => 'ge',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000505/eventlogging?orgId=1&viewPanel=13'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/EventLogging/Administration',
    }

    # Alarms if p50 of Navigation Timing event throughput goes under 1 req/sec
    # in a 15 min period
    # https://meta.wikimedia.org/wiki/Schema:NavigationTiming
    monitoring::check_prometheus { 'eventlogging_NavigationTiming_throughput':
        description     => 'Throughput of EventLogging NavigationTiming events',
        query           => 'scalar(quantile(0.50,sum(rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{cluster="kafka_jumbo",topic="eventlogging_NavigationTiming"}[15m]))))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
        warning         => 1,
        critical        => 0,
        method          => 'le',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000505/eventlogging?orgId=1&viewPanel=6'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/EventLogging/Administration',
    }

    # Warn if p50 of overall event throughput goes beyond 1500 events/s
    # in a 15 min period.
    # These thresholds are somewhat arbtirary.
    monitoring::check_prometheus { 'eventlogging_throughput':
        description     => 'Throughput of EventLogging events',
        query           => 'scalar(quantile(0.50,sum(rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{cluster="kafka_jumbo",topic="eventlogging-client-side"}[15m]))))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
        warning         => 6000,
        critical        => 8000,
        method          => 'ge',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000505/eventlogging?orgId=1&viewPanel=6'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/EventLogging/Administration',
    }

    # Alert if the Kafka consumer lag of EL's processors builds up. This usually means that EL
    # is not processing events, or for some reason it slowed down a lot and can't keep up anymore.
    monitoring::check_prometheus { 'eventlogging_processors_kafka_lag':
        description     => 'Kafka Consumer lag of the EventLogging processors',
        query           => 'scalar(sum(kafka_burrow_partition_lag{exported_cluster="jumbo-eqiad",topic="eventlogging-client-side",group="eventlogging_processor_client_side_00"}))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
        warning         => 250000,
        critical        => 500000,
        check_interval  => 60,
        method          => 'ge',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000484/kafka-consumer-lag?orgId=1&prometheus=ops&var-cluster=jumbo-eqiad&var-topic=All&var-consumer_group=eventlogging_processor_client_side_00'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/EventLogging/Administration',
    }


    # Declare validation error rate alerts for each eventgate service.
    # https://phabricator.wikimedia.org/T257237
    $eventgate_services_validation_error_thresholds = {
        # eventgate-main should have no validation errors.
        'eventgate-main' => {
            'warning' => 0.0,
            'critical' => 0.5,
            'contact_group' => 'admins',
        },
        # eventgate-analytics usually has no validation errors,
        # but if it does it isn't a critical production problem.
        'eventgate-analytics' => {
            'warning' => 0.0,
            'critical' => 1.0,
            'contact_group' => 'analytics',
        },
        # eventgate-analytics-external will almost always have validation errors,
        # since we accept events from external client.
        'eventgate-analytics-external' => {
            'warning' => 1.0,
            'critical' => 2.0,
            'contact_group' => 'analytics',
        },
        # eventgate-analytics-external will probably have validation errors,
        # since we accept events from external client, but so far it doesn't have many if any.
        'eventgate-logging-external' => {
            'warning' => 0.1,
            'critical' => 0.5,
            'contact_group' => 'admins',
        },
    }
    $eventgate_services_validation_error_thresholds.each |String $eventgate_service, Hash $params| {
        # Alert if validation error rate throughput goes above thresholds in a 15 minute period.
        monitoring::check_prometheus { "${eventgate_service}_validation_error_rate":
            description     => "${eventgate_service} validation error rate too high",
            query           => "sum(rate(eventgate_validation_errors_total{service=\"${eventgate_service}\"} [15m]))",
            prometheus_url  => 'https://thanos-query.discovery.wmnet',
            warning         => $params['warning'],
            critical        => $params['critical'],
            method          => 'gt',
            dashboard_links => ["https://grafana.wikimedia.org/d/ZB39Izmnz/eventgate?orgId=1&refresh=1m&var-service=${eventgate_service}&var-stream=All&var-kafka_broker=All&var-kafka_producer_type=All&var-dc=thanos"],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
            contact_group   => $params['contact_group']
        }
    }


    # NOTE: To be removed in favor of the eventgate_validation_errors_total based alerts above.
    monitoring::alerts::kafka_topic_throughput { 'eventgate-analytics_validation_errors':
        ensure             => 'absent',
        kafka_cluster_name => 'jumbo-eqiad',
        topic              => '.*\.eventgate-analytics\.error\.validation',
        method             => 'gt',
        warning            => 0.0,
        # 1 per second rate over the last 15 minutes.
        critical           => 1.0,
        contact_group      => 'analytics',
        dashboard_links    => ['https://grafana.wikimedia.org/d/ZB39Izmnz/eventgate?refresh=1m&orgId=1&var-dc=eqiad+prometheus/k8s&var-service=eventgate-analytics&var-kafka_topic=All&var-kafka_broker=All&var-kafka_producer_type=All'],
    }
    monitoring::alerts::kafka_topic_throughput { 'eventgate-main_validation_errors':
        ensure             => 'absent',
        kafka_cluster_name => 'jumbo-eqiad',
        topic              => '.*\.eventgate-main\.error\.validation',
        method             => 'gt',
        warning            => 0.0,
        # 0.5 per second rate over the last 15 minutes.
        critical           => 0.5,
        dashboard_links    => ['https://grafana.wikimedia.org/d/ZB39Izmnz/eventgate?refresh=1m&orgId=1&var-dc=eqiad+prometheus/k8s&var-service=eventgate-main&var-kafka_topic=All&var-kafka_broker=All&var-kafka_producer_type=All'],
    }

    ['eqiad', 'codfw'].each |String $site| {
        monitoring::check_prometheus { "eventgate_logging_external_latency_${site}":
            description     => "Elevated latency for eventgate-logging-external ${site}",
            query           => 'service_method:service_runner_request_duration_seconds:90pct5m{service="eventgate-logging-external"}',
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/k8s",
            warning         => 0.5,
            critical        => 1,
            method          => 'ge',
            dashboard_links => ["https://grafana.wikimedia.org/d/ZB39Izmnz/eventgate?orgId=1&refresh=1m&var-dc=${site}+prometheus/k8s&var-service=eventgate-logging-external"],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
        }

        monitoring::check_prometheus { "eventgate_logging_external_errors_${site}":
            description     => "Elevated errors for eventgate-logging-external ${site}",
            query           => 'service_status:service_runner_request_duration_seconds:50pct5m{service="eventgate-logging-external",status="5xx"}',
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/k8s",
            warning         => 0.5,
            critical        => 1,
            method          => 'ge',
            dashboard_links => ["https://grafana.wikimedia.org/d/ZB39Izmnz/eventgate?orgId=1&refresh=1m&var-dc=${site}+prometheus/k8s&var-service=eventgate-logging-external"],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
        }
    }

    monitoring::check_prometheus { 'widespread-puppet-agent-fail':
        description     => 'Widespread puppet agent failures',
        dashboard_links => ['https://grafana.wikimedia.org/d/yOxVDGvWk/puppet'],
        query           => 'sum(cluster:puppet_agent_failed:sum) / sum(cluster:puppet_agent_failed:count)',
        warning         => 0.006,
        critical        => 0.01,
        method          => 'ge',
        retries         => 2,
        # Icinga will query the site-local Prometheus 'global' instance
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/global",
        notes_link      => 'https://puppetboard.wikimedia.org/nodes?status=failed',
    }

    monitoring::check_prometheus { 'widespread-puppet-agent-no-resources':
        description     => 'Widespread puppet agent failures, no resources reported',
        dashboard_links => ['https://grafana.wikimedia.org/d/yOxVDGvWk/puppet'],
        query           => 'sum(cluster:puppet_agent_resources_total:count0) / sum(cluster:puppet_agent_resources_total:count)',
        warning         => 0.006,
        critical        => 0.01,
        method          => 'ge',
        retries         => 2,
        # Icinga will query the site-local Prometheus 'global' instance
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/global",
    }

    # Perform aggregate ipsec checks per-datacenter (site) to ease downtimes/maintenance
    $datacenters.each |String $datacenter| {
        monitoring::alerts::aggregate_ipsec{"aggregate_ipsec_${datacenter}": site => $datacenter }
    }
}
