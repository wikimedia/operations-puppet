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
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/prometheus-druid?refresh=1m&panelId=41&fullscreen&orgId=1']
    }

    # Eventlogging

    # Warn if p75 of overall error event throughput goes above 20 events/s
    # in a 15 minute period.
    # The EventError topic counted here includes both events that do not
    # validate and events that can not be processed for other reasons
    monitoring::check_prometheus { 'eventlogging_EventError_throughput':
        description     => 'Throughput of EventLogging EventError events',
        query           => 'scalar(quantile(0.75,rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{cluster="kafka_jumbo",topic="eventlogging_EventError"}[15m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/analytics',
        warning         => 20,
        critical        => 30,
        method          => 'ge',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventlogging?panelId=13&fullscreen&orgId=1'],
    }

    # Alarms if p75 of Navigation Timing event throughput goes under 1 req/sec
    # in a 15 min period
    # https://meta.wikimedia.org/wiki/Schema:NavigationTiming
    monitoring::check_prometheus { 'eventlogging_NavigationTiming_throughput':
        description     => 'Throughput of EventLogging NavigationTiming events',
        query           => 'scalar(quantile(0.75,rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{cluster="kafka_jumbo",topic="eventlogging_NavigationTiming"}[15m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/analytics',
        warning         => 1,
        critical        => 0,
        method          => 'le',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventlogging?panelId=6&fullscreen&orgId=1'],
    }

    # Warn if p75 of overall event throughput goes beyond 1000 events/s
    # in a 15 min period.
    # These thresholds are somewhat arbtirary.
    monitoring::check_prometheus { 'eventlogging_throughput':
        description     => 'Throughput of EventLogging events',
        query           => 'scalar(quantile(0.75, rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{cluster="kafka_jumbo",topic="eventlogging-client-side"}[15m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/analytics',
        warning         => 1000,
        critical        => 5000,
        method          => 'ge',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventlogging?panelId=6&fullscreen&orgId=1'],
    }
}