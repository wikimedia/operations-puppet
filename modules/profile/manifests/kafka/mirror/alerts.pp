# == Define profile::kafka::mirror::alerts
#
# Installs check_prometheus jobs to alert for MirrorMaker throughput and dropped messages.
#
# Dropped messages will generate a warning at greater than 0 and critical at greater than
# 10 dropped messages in the last $monitoring_period.
#
# [*mirror_name*]
#   This must match a the title of a declared confluent::kafka::mirror::instance.
#   Default: $title
#
# [*monitoring_period*]
#   Prometheus range period to monitor.  Default: 30m.
#
# [*warning_throughput*]
#   Alert warning if average consume or produce throughput (msgs/sec) drops below this.
#   Default: 100
#
# [*critical_throughput*]
#   Alert critical if average consume or produce throughput (msgs/sec) drops below this.
#
# [*contact_group*]
#   Default: admins
#
# [*nagios_critical*]
#   Default: false
#
define profile::kafka::mirror::alerts(
    $mirror_name         = $title,
    $monitoring_period   = '30m',
    $warning_throughput  = 100,
    $critical_throughput = 0,
    $contact_group       = 'admins',
    $nagios_critical     = false,
) {
    $prometheus_url    = "http://prometheus.svc.${::site}.wmnet"
    $dashboard_url     = "https://grafana.wikimedia.org/dashboard/db/kafka-mirrormaker?var-datasource=eqiad%20prometheus%2Fops&var-mirror_name=${mirror_name}"

    # Set check_prometheus defaults.
    Monitoring::Check_prometheus {
        prometheus_url  => $prometheus_url,
        method          => 'le',
        warning         => $warning_throughput,
        critical        => $critical_throughput,
        nagios_critical => $nagios_critical,
        contact_group   => $contact_group,
        dashboard_links => [$dashboard_url],
    }

    monitoring::check_prometheus { "kafka-mirror-${mirror_name}-consume_rate":
        description => "Kafka MirrorMaker ${mirror_name} average message consume rate in last ${monitoring_period}",
        query       => "scalar(sum(sum_over_time(kafka_consumer_consumer_fetch_manager_metrics_all_topics_records_consumed_rate{mirror_name=~\"${mirror_name}.*\",job=\"jmx_kafka\"} [${monitoring_period}])))",
    }

    monitoring::check_prometheus { "kafka-mirror-${mirror_name}-produce_rate":
        description => "Kafka MirrorMaker ${mirror_name} average message produce rate in last ${monitoring_period}",
        # This metric does not have the mirror_name label, so we target it in the client_id instead.
        query       => "scalar(sum(avg_over_time(kafka_producer_producer_metrics_record_send_rate{client_id=~\"kafka-mirror-${mirror_name}.*\",job=\"jmx_kafka\"} [${monitoring_period}])))",
    }

    monitoring::check_prometheus { "kafka-mirror-${mirror_name}-dropped_messages":
        description => "Kafka MirrorMaker ${mirror_name} dropped message count in last ${monitoring_period}",
        query       => "increase(kafka_tools_MirrorMaker_MirrorMaker_numDroppedMessages{mirror_name=\"${mirror_name}\"} [${monitoring_period}])",
        method      => 'gt',
        # This really should not happen, so alert early.
        warning     => 0,
        critical    => 10,
    }
}
