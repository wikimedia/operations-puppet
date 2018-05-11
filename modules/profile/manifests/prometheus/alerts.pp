# == Class: profile::prometheus::alerts
#
# Install icinga alerts based on Prometheus metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class profile::prometheus::alerts {

    # Monitor Druid realtime ingestion event rate.
    # Experimental, only alerting the Analytics alias.
    monitoring::check_prometheus { 'druid_realtime_banner_activity':
        description     => 'Number of banner_activity realtime events received by Druid over a 30 minutes period',
        query           => 'scalar(sum(sum_over_time(druid_realtime_ingest_events_processed_count{cluster="druid_analytics", instance=~"druid.*:8000", datasource=~"banner_activity_minutely"}[30m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/analytics',
        method          => 'le',
        warning         => 10,
        critical        => 0,
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/druid?refresh=1m&panelId=41&fullscreen&orgId=1']
    }

    # Monitor Druid segments reported as unavailable by the Coordinator
    monitoring::check_prometheus { 'druid_coordinator_segments_unavailable_analytics':
        description     => 'Number of segments reported as unavailable by the Druid Coordinators of the Analytics cluster',
        query           => 'scalar(avg(druid_coordinator_segment_unavailable_count{cluster="druid_analytics", instance=~"druid.*:8000", datasource=~".*"}))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/analytics',
        method          => 'gt',
        warning         => 5,
        critical        => 10,
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/druid?refresh=1m&panelId=46&fullscreen&orgId=1&var-cluster=druid_analytics&var-druid_datasource=All']
    }

    monitoring::check_prometheus { 'druid_coordinator_segments_unavailable_public':
        description     => 'Number of segments reported as unavailable by the Druid Coordinators of the Public cluster',
        query           => 'scalar(avg(druid_coordinator_segment_unavailable_count{cluster="druid_public", instance=~"druid.*:8000", datasource=~".*"}))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/analytics',
        method          => 'gt',
        warning         => 5,
        critical        => 10,
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/druid?refresh=1m&panelId=46&fullscreen&orgId=1&var-cluster=druid_public&var-druid_datasource=All']
    }

    # Monitor throughput and dropped messages on MirrorMaker instances.
    # main-eqiad -> jumbo MirrorMaker
    profile::kafka::mirror::alerts { 'main-eqiad_to_jumbo-eqiad':
        #  For now, alert analytics admins, until alerts are more stable.
        contact_group   => 'analytics',
        topic_blacklist => '.*(change-prop|\.job\.).*',
    }
    # main-eqiad -> analytics-eqiad (called 'eqiad' for history reasons).
    # This will be removed once the analytics Kafka cluster is decommed.
    profile::kafka::mirror::alerts { 'main-eqiad_to_eqiad':
        #  For now, alert analytics admins, until alerts are more stable.
        contact_group   => 'analytics',
        topic_blacklist => '.*(change-prop|\.job\.).*',
    }

    # Cross DC main-eqiad <-> main-codfw MirrorMakers.
    profile::kafka::mirror::alerts { 'main-eqiad_to_main-codfw':
        #  For now, alert analytics admins, until alerts are more stable.
        contact_group         => 'analytics',
        prometheus_url        => 'http://prometheus.svc.codfw.wmnet/ops',
        source_prometheus_url => 'http://prometheus.svc.eqiad.wmnet/ops',
        # Less data (resource_change) from main eqiad -> codfw.
        warning_throughput    => 25,
    }
    profile::kafka::mirror::alerts { 'main-codfw_to_main-eqiad':
        #  For now, alert analytics admins, until alerts are more stable.
        contact_group         => 'analytics',
        prometheus_url        => 'http://prometheus.svc.eqiad.wmnet/ops',
        source_prometheus_url => 'http://prometheus.svc.codfw.wmnet/ops',
    }


    # Eventlogging

    # Warn if p50 of overall error event throughput goes above 20 events/s
    # in a 15 minute period.
    # The EventError topic counted here includes both events that do not
    # validate and events that can not be processed for other reasons
    monitoring::check_prometheus { 'eventlogging_EventError_throughput':
        description     => 'Throughput of EventLogging EventError events',
        query           => 'scalar(quantile(0.50,rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{cluster="kafka_jumbo",topic="eventlogging_EventError"}[15m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
        warning         => 20,
        critical        => 30,
        method          => 'ge',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventlogging?panelId=13&fullscreen&orgId=1'],
    }

    # Alarms if p50 of Navigation Timing event throughput goes under 1 req/sec
    # in a 15 min period
    # https://meta.wikimedia.org/wiki/Schema:NavigationTiming
    monitoring::check_prometheus { 'eventlogging_NavigationTiming_throughput':
        description     => 'Throughput of EventLogging NavigationTiming events',
        query           => 'scalar(quantile(0.50,rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{cluster="kafka_jumbo",topic="eventlogging_NavigationTiming"}[15m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
        warning         => 1,
        critical        => 0,
        method          => 'le',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventlogging?panelId=6&fullscreen&orgId=1'],
    }

    # Warn if p50 of overall event throughput goes beyond 1500 events/s
    # in a 15 min period.
    # These thresholds are somewhat arbtirary.
    monitoring::check_prometheus { 'eventlogging_throughput':
        description     => 'Throughput of EventLogging events',
        query           => 'scalar(quantile(0.50, rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{cluster="kafka_jumbo",topic="eventlogging-client-side"}[15m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
        warning         => 1500,
        critical        => 5000,
        method          => 'ge',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventlogging?panelId=6&fullscreen&orgId=1'],
    }

    monitoring::alerts::http_availability{'http_availability_eqiad': site => 'eqiad'}
    monitoring::alerts::http_availability{'http_availability_codfw': site => 'codfw'}
    monitoring::alerts::http_availability{'http_availability_esams': site => 'esams'}
    monitoring::alerts::http_availability{'http_availability_ulsfo': site => 'ulsfo'}
    monitoring::alerts::http_availability{'http_availability_eqsin': site => 'eqsin'}
}
