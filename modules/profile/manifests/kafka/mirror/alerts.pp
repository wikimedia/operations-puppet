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
#   Default: 0
#
# [*warning_lag*]
#   Alert warning if max consumer lag in the last 10 minutes is above this.
#   Default: 10000
#
# [*critical_lag*]
#   Alert critical if max consumer lag in the last 10 minutes is above this.
#   Default: 100000
#
# [*contact_group*]
#   Default: admins
#
# [*nagios_critical*]
#   Default: false
#
# [*prometheus_url*]
#   Default: "http://prometheus.svc.${::site}.wmnet/ops"
#
define profile::kafka::mirror::alerts(
    $mirror_name         = $title,
    $monitoring_period   = '30m',
    $warning_throughput  = 100,
    $critical_throughput = 0,
    $warning_lag         = 10000,
    $critical_lag        = 100000,
    $contact_group       = 'admins',
    $nagios_critical     = false,
    $prometheus_url      = "http://prometheus.svc.${::site}.wmnet/ops",
) {
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
        query       => "scalar(sum(avg_over_time(kafka_consumer_consumer_fetch_manager_metrics_all_topics_records_consumed_rate{mirror_name=\"${mirror_name}\"} [${monitoring_period}])))",
    }

    monitoring::check_prometheus { "kafka-mirror-${mirror_name}-produce_rate":
        description => "Kafka MirrorMaker ${mirror_name} average message produce rate in last ${monitoring_period}",
        # This metric does not have the mirror_name label, so we target it in the client_id instead.
        query       => "scalar(sum(avg_over_time(kafka_producer_producer_metrics_record_send_rate{client_id=~\"kafka-mirror-.+-${mirror_name}@[0-9]+\"} [${monitoring_period}])))",
    }

    monitoring::check_prometheus { "kafka-mirror-${mirror_name}-dropped_messages":
        description => "Kafka MirrorMaker ${mirror_name} dropped message count in last ${monitoring_period}",
        query       => "scalar(sum(increase(kafka_tools_MirrorMaker_MirrorMaker_numDroppedMessages{mirror_name=\"${mirror_name}\"} [${monitoring_period}])))",
        method      => 'gt',
        # numDroppedMessages here doesn't really mean that messages were lost.
        # abort.on.send.failure defaults to true, so any MirrorMaker process that encounters
        # this will die before committing the offset for any dropped messages.  This will
        # cause these messages to be reconsumed and produced again by another MirrorMaker process.
        # https://github.com/apache/kafka/blob/trunk/core/src/main/scala/kafka/tools/MirrorMaker.scala#L741-L747
        # We alert on this, but are lenient about them.
        warning     => 100,
        critical    => 1000,
    }

    # Alert on max consumer lag in last $lag_check_period minutes.
    $lag_check_period = '10'
    monitoring::check_prometheus { "kafka-mirror-${mirror_name}-consumer_max_lag":
        description => "Kafka MirrorMaker ${mirror_name} max lag in last ${lag_check_period} minutes",
        # This metric does not have the mirror_name label, so we target it in the group instead.
        query       => "scalar(max(max_over_time(kafka_burrow_partition_lag{group=\"kafka-mirror-${mirror_name}\"} [${lag_check_period}m])))",
        method      => 'gt',
        warning     => $warning_lag,
        critical    => $critical_lag,
    }
}
