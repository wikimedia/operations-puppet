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
# [*topic_blacklist*]
#   Regex of topics to exclude from lag monitoring.  Default: undef
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
#   Prometheus URL endpoint containing metrics for MirrorMaker.
#   Default: "http://prometheus.svc.${::site}.wmnet/ops"
#
# [*source_prometheus_url*]
#   Prometheus URL endpoint containing metrics for the source Kafka cluster,
#   including lag metrics from burrow, etc.
#   Default: "http://prometheus.svc.${::site}.wmnet/ops"
#
define profile::kafka::mirror::alerts(
    $mirror_name           = $title,
    $topic_blacklist       = undef,
    $monitoring_period     = '30m',
    $warning_throughput    = 100,
    $critical_throughput   = 0,
    $warning_lag           = 10000,
    $critical_lag          = 100000,
    $contact_group         = 'admins',
    $nagios_critical       = false,
    $prometheus_url        = "http://prometheus.svc.${::site}.wmnet/ops",
    $source_prometheus_url = "http://prometheus.svc.${::site}.wmnet/ops",
) {
    # Extract grafana datasources from $prometheus_urls for the dashboard url.
    $grafana_datasource     = regsubst($prometheus_url,        '^.+prometheus\.svc\.(.+)\.wmnet/(.+)$', '\1 prometheus/\2')
    $grafana_lag_datasource = regsubst($source_prometheus_url, '^.+prometheus\.svc\.(.+)\.wmnet/(.+)$', '\1 prometheus/\2')
    $dashboard_url          = "https://grafana.wikimedia.org/dashboard/db/kafka-mirrormaker?var-datasource=${grafana_datasource}&var-lag_datasource=${grafana_lag_datasource}&var-mirror_name=${mirror_name}"

    # Set check_prometheus defaults.
    Monitoring::Check_prometheus {
        # Most metrics are for MirrorMaker, so default to its $prometheus_url.
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
        notes_link  => 'https://wikitech.wikimedia.org/wiki/Kafka/Administration#MirrorMaker',
    }

    monitoring::check_prometheus { "kafka-mirror-${mirror_name}-produce_rate":
        description => "Kafka MirrorMaker ${mirror_name} average message produce rate in last ${monitoring_period}",
        query       => "scalar(sum(avg_over_time(kafka_producer_producer_metrics_record_send_rate{mirror_name=\"${mirror_name}\"} [${monitoring_period}])))",
        notes_link  => 'https://wikitech.wikimedia.org/wiki/Kafka/Administration',
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
        notes_link  => 'https://wikitech.wikimedia.org/wiki/Kafka/Administration',
    }

    # Alert on max consumer lag in last $lag_check_period minutes.
    #
    # The change-prop topics are currently not replicated but due to previous tests,
    # the commits/offsets registered for those within the mirror maker consumer
    # group were not deleted from Kafka. They still end up in the Burrow's metrics
    # for the mirror maker consumer group, showing a constant lag that triggers the alarm.
    $lag_check_period = '10'

    if topic_blacklist {
        $cgroup_lag_query = "scalar(max(max_over_time(kafka_burrow_partition_lag{group=\"kafka-mirror-${mirror_name}\",topic\\!~\"${topic_blacklist}\"} [${lag_check_period}m])))"
    } else {
        $cgroup_lag_query = "scalar(max(max_over_time(kafka_burrow_partition_lag{group=\"kafka-mirror-${mirror_name}\"} [${lag_check_period}m])))"
    }
    monitoring::check_prometheus { "kafka-mirror-${mirror_name}-consumer_max_lag":
        description    => "Kafka MirrorMaker ${mirror_name} max lag in last ${lag_check_period} minutes",
        # This metric does not have the mirror_name label, so we target it in the group instead.
        query          => $cgroup_lag_query,
        method         => 'gt',
        warning        => $warning_lag,
        critical       => $critical_lag,
        retry_interval => 10,
        retries        => 3,
        prometheus_url => $source_prometheus_url,
        notes_link     => 'https://wikitech.wikimedia.org/wiki/Kafka/Administration',
    }
}
