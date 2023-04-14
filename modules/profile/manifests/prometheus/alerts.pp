# SPDX-License-Identifier: Apache-2.0
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
}
