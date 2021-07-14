# == Class: profile::prometheus::alerts
#
# Install icinga alerts based on Prometheus metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class profile::prometheus::alerts (
    Array[String] $datacenters = lookup('datacenters'),
) {

    # Monitor Druid realtime ingestion event rate.
    monitoring::check_prometheus { 'druid_netflow_supervisor':
        description     => 'Number of Netflow realtime events received by Druid over a 30 minutes period',
        query           => 'scalar(sum(sum_over_time(druid_realtime_ingest_events_processed_count{cluster="druid_analytics", instance=~".*:8000", datasource=~"wmf_netflow"}[30m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/analytics',
        method          => 'le',
        warning         => 10,
        critical        => 0,
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/druid?refresh=1m&var-cluster=druid_analytics&panelId=41&fullscreen&orgId=1']
    }

    # Monitor Druid segments reported as unavailable by the Coordinator
    monitoring::check_prometheus { 'druid_coordinator_segments_unavailable_analytics':
        description     => 'Number of segments reported as unavailable by the Druid Coordinators of the Analytics cluster',
        query           => 'scalar(sum(sum_over_time(druid_coordinator_segment_unavailable_count{cluster="druid_analytics", instance=~".*:8000", datasource=~".*"}[15m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/analytics',
        method          => 'gt',
        warning         => 180,
        critical        => 200,
        retry_interval  => 15,
        retries         => 6,
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/druid?refresh=1m&panelId=46&fullscreen&orgId=1&var-cluster=druid_analytics&var-druid_datasource=All'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Druid#Troubleshooting',
    }

    monitoring::check_prometheus { 'druid_coordinator_segments_unavailable_public':
        description     => 'Number of segments reported as unavailable by the Druid Coordinators of the Public cluster',
        query           => 'scalar(sum(sum_over_time(druid_coordinator_segment_unavailable_count{cluster="druid_public", instance=~".*:8000", datasource=~".*"}[15m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/analytics',
        method          => 'gt',
        warning         => 180,
        critical        => 200,
        retry_interval  => 15,
        retries         => 6,
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/druid?refresh=1m&panelId=46&fullscreen&orgId=1&var-cluster=druid_public&var-druid_datasource=All'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Druid#Troubleshooting',
    }

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
        # Less data (resource_change) from main eqiad -> codfw.
        warning_throughput    => 25,
    }
    profile::kafka::mirror::alerts { 'main-codfw_to_main-eqiad':
        #  For now, alert analytics admins, until alerts are more stable.
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
        query           => 'scalar(quantile(0.50,sum(rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{cluster="kafka_jumbo",topic="eventlogging_EventError"}[15m]))))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
        warning         => 20,
        critical        => 30,
        method          => 'ge',
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventlogging?panelId=13&fullscreen&orgId=1'],
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
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventlogging?panelId=6&fullscreen&orgId=1'],
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
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/eventlogging?panelId=6&fullscreen&orgId=1'],
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
            dashboard_links => ["https://grafana.wikimedia.org/d/ePFPOkqiz/eventgate?orgId=1&refresh=1m&var-service=${eventgate_service}&var-stream=All&var-kafka_broker=All&var-kafka_producer_type=All&var-dc=thanos"],
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
        dashboard_links    => ['https://grafana.wikimedia.org/d/ePFPOkqiz/eventgate?refresh=1m&orgId=1&var-dc=eqiad+prometheus/k8s&var-service=eventgate-analytics&var-kafka_topic=All&var-kafka_broker=All&var-kafka_producer_type=All'],
    }
    monitoring::alerts::kafka_topic_throughput { 'eventgate-main_validation_errors':
        ensure             => 'absent',
        kafka_cluster_name => 'jumbo-eqiad',
        topic              => '.*\.eventgate-main\.error\.validation',
        method             => 'gt',
        warning            => 0.0,
        # 0.5 per second rate over the last 15 minutes.
        critical           => 0.5,
        dashboard_links    => ['https://grafana.wikimedia.org/d/ePFPOkqiz/eventgate?refresh=1m&orgId=1&var-dc=eqiad+prometheus/k8s&var-service=eventgate-main&var-kafka_topic=All&var-kafka_broker=All&var-kafka_producer_type=All'],
    }

    ['eqiad', 'codfw'].each |String $site| {
        monitoring::check_prometheus { "eventgate_logging_external_latency_${site}":
            description     => "Elevated latency for eventgate-logging-external ${site}",
            query           => 'service_method:service_runner_request_duration_seconds:90pct5m{service="eventgate-logging-external"}',
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/k8s",
            warning         => 0.5,
            critical        => 1,
            method          => 'ge',
            dashboard_links => ["https://grafana.wikimedia.org/d/ePFPOkqiz/eventgate?orgId=1&refresh=1m&var-dc=${site}+prometheus/k8s&var-service=eventgate-logging-external"],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
        }

        monitoring::check_prometheus { "eventgate_logging_external_errors_${site}":
            description     => "Elevated errors for eventgate-logging-external ${site}",
            query           => 'service_status:service_runner_request_duration_seconds:50pct5m{service="eventgate-logging-external",status="5xx"}',
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/k8s",
            warning         => 0.5,
            critical        => 1,
            method          => 'ge',
            dashboard_links => ["https://grafana.wikimedia.org/d/ePFPOkqiz/eventgate?orgId=1&refresh=1m&var-dc=${site}+prometheus/k8s&var-service=eventgate-logging-external"],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate',
        }
    }

    monitoring::alerts::http_availability{'global_availability':}

    monitoring::alerts::traffic_drop{'traffic_drop_eqiad': site => 'eqiad'}
    monitoring::alerts::traffic_drop{'traffic_drop_codfw': site => 'codfw'}
    monitoring::alerts::traffic_drop{'traffic_drop_esams': site => 'esams'}
    monitoring::alerts::traffic_drop{'traffic_drop_ulsfo': site => 'ulsfo'}
    monitoring::alerts::traffic_drop{'traffic_drop_eqsin': site => 'eqsin'}

    monitoring::check_prometheus { 'too_many_network_error_logging':
        description     => 'Too high an incoming rate of browser-reported Network Error Logging events',
        # We restrict to two types we believe to best correlate with actionable issues that aren't caught
        # by other monitoring.
        # This computes a per-second rate.
        query           => 'sum by (type) (log_w3c_networkerror_type_doc_count{type=~"tcp.(address_unreachable|timed_out)"}) / 60',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        warning         => 1.5,
        critical        => 2,
        method          => 'ge',
        dashboard_links => ['https://logstash.wikimedia.org/goto/5c8f4ca1413eda33128e5c5a35da7e28'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Network_monitoring#NEL_alerts',
    }

    monitoring::alerts::rsyslog{'rsyslog_eqiad': site => 'eqiad'}
    monitoring::alerts::rsyslog{'rsyslog_codfw': site => 'codfw'}
    monitoring::alerts::rsyslog{'rsyslog_esams': site => 'esams'}
    monitoring::alerts::rsyslog{'rsyslog_ulsfo': site => 'ulsfo'}
    monitoring::alerts::rsyslog{'rsyslog_eqsin': site => 'eqsin'}

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

    monitoring::check_prometheus { 'prometheus-job-unavailable':
        description     => 'Prometheus jobs reduced availability',
        dashboard_links => ['https://grafana.wikimedia.org/d/NEJu05xZz/prometheus-targets'],
        # See https://phabricator.wikimedia.org/T276749 for netbox_device_statistics
        query           => 'site_job:up:avail{job\!="netbox_device_statistics"}',
        warning         => 0.6,
        critical        => 0.5,
        method          => 'le',
        retries         => 2,
        # Icinga will query the site-local Prometheus 'global' instance
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/global",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Prometheus#Prometheus_job_unavailable',
    }

    # Check metrics from Prometheus exporters about the underlying service
    # health (e.g. was the exporter able to gather metrics from the service?)
    # Upon changing this list the expression on this panel needs updating too:
    # https://grafana.wikimedia.org/d/NEJu05xZz/prometheus-targets?orgId=1&fullscreen&panelId=5
    [ 'apache_up', 'elasticsearch_node_stats_up', 'etherpad_up',
      'haproxy_up', 'ipsec_up', 'mcrouter_up',
      'memcached_up', 'mysql_up', 'nutcracker_up', 'openldap_up',
      'pg_up', 'phpfpm_up', 'redis_up', 'varnish_up' ].each |String $metric| {
        monitoring::check_prometheus { "${metric}_unavailable":
            description     => "${metric} reduced availability",
            dashboard_links => ['https://grafana.wikimedia.org/d/NEJu05xZz/prometheus-targets'],
            query           => "sum(${metric}) / count(${metric})",
            warning         => 0.9,
            critical        => 0.8,
            method          => 'le',
            retries         => 2,
            # Icinga will query the site-local Prometheus 'global' instance
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/global",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Prometheus#Prometheus_exporters_"up"_metrics_unavailable',
        }
    }

    # Perform aggregate ipsec checks per-datacenter (site) to ease downtimes/maintenance
    $datacenters.each |String $datacenter| {
        monitoring::alerts::aggregate_ipsec{"aggregate_ipsec_${datacenter}": site => $datacenter }
    }

    # Check for stale textfiles exported by node-exporter
    # Files that rarely change (e.g. atlas_metadata.prom) are not included.
    $datacenters.each |String $site| {
        monitoring::check_prometheus { "node_textfile_stale_${site}":
            description     => "Stale file for node-exporter textfile in ${site}",
            query           => 'time() - node_textfile_mtime_seconds{file\!="atlas_metadata.prom"}',
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
            warning         => 60*60*24*2,
            critical        => 60*60*24*4,
            method          => 'ge',
            dashboard_links => ['https://grafana.wikimedia.org/d/knkl4dCWz/node-exporter-textfile'],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Prometheus#Stale_file_for_node-exporter_textfile',
            check_interval  => 20,
            retries         => 3,
        }
    }

    # Check for signs of icinga overload
    ['eqiad', 'codfw'].each |String $site| {
        monitoring::check_prometheus { "icinga_check_latency_${site}":
            description     => "Elevated latency for icinga checks in ${site}",
            query           => 'icinga_avg_check_latency',
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
            warning         => 85,
            critical        => 110,
            method          => 'ge',
            dashboard_links => ['https://grafana.wikimedia.org/d/rsCfQfuZz/icinga'],
            check_interval  => 5,
            retries         => 3,
        }
    }
}
