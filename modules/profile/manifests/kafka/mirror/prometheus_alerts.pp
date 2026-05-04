# SPDX-License-Identifier: Apache-2.0
# == Define profile::kafka::mirror::prometheus_alerts
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
# [*team*]
#   Default: sre
#
# [*prometheus_site*]
#   Prometheus site containing metrics for MirrorMaker.
#   Default: "${::site}"
#
# [*prometheus_instance*]
#   Prometheus instance containing metrics for MirrorMaker.
#   Default: "${::site}"
#
# [*source_prometheus_site*]
#   Prometheus site containing metrics for the source Kafka cluster,
#   including lag metrics from burrow, etc.
#   Default: ops
#
# [*source_prometheus_instance*]
#   Prometheus instance containing metrics for the source Kafka cluster,
#   including lag metrics from burrow, etc.
#   Default: ops
#
define profile::kafka::mirror::prometheus_alerts(
    $mirror_name                  = $title,
    $topic_blacklist              = undef,
    $monitoring_period            = '30m',
    $warning_throughput           = 100,
    $critical_throughput          = 0,
    $warning_lag                  = 10000,
    $critical_lag                 = 100000,
    $team                         = 'sre',
    $prometheus_site              = $::site,
    $prometheus_instance          = 'ops',
    $source_prometheus_site       = $::site,
    $source_prometheus_instance   = 'ops',
) {
    # Extract grafana datasources from $prometheus_urls for the dashboard url.
    $grafana_datasource     = "${prometheus_site} prometheus/${prometheus_instance}"
    $grafana_lag_datasource = "${source_prometheus_site} prometheus/${source_prometheus_instance}"
    $dashboard_url          = "https://grafana.wikimedia.org/d/000000521/kafka-mirrormaker?var-datasource=${grafana_datasource}&var-lag_datasource=${grafana_lag_datasource}&var-mirror_name=${mirror_name}"

    # Set prometheus::alert::rule defaults.
    Prometheus::Alert::Rule {
        dashboard   => $dashboard_url,
        runbook     => 'https://wikitech.wikimedia.org/wiki/Kafka/Administration#MirrorMaker',
        team        => $team,
        site        => $prometheus_site,
        instance    => $prometheus_instance
    }

    prometheus::alert::rule { "KmmAvgMsgConsumeRateWarning-${mirror_name}":
        group       => 'KafkaMirrorMaker',
        alert_name  => 'KafkaMirrorMakerAvgMsgConsumeRate',
        description => "Kafka MirrorMaker ${mirror_name} average message consume rate in last ${monitoring_period}",
        summary     => "Kafka MirrorMaker ${mirror_name} average message consume rate in last ${monitoring_period}",
        expr        => "sum(avg_over_time(kafka_consumer_consumer_fetch_manager_metrics_all_topics_records_consumed_rate{mirror_name=\"${mirror_name}\"} [${monitoring_period}])) <= ${warning_throughput}",
        #for         => "${defaultCheck_interval + (($defaultRetries - 1) * $defaultRetry_interval)}m",
        for         => '3m',
        #severity    => 'warning'
        severity    => 'info'
    }

    prometheus::alert::rule { "KmmAvgMsgConsumeRateCritical-${mirror_name}":
        group       => 'KafkaMirrorMaker',
        alert_name  => 'KafkaMirrorMakerAvgMsgConsumeRate',
        description => "Kafka MirrorMaker ${mirror_name} average message consume rate in last ${monitoring_period}",
        summary     => "Kafka MirrorMaker ${mirror_name} average message consume rate in last ${monitoring_period}",
        expr        => "sum(avg_over_time(kafka_consumer_consumer_fetch_manager_metrics_all_topics_records_consumed_rate{mirror_name=\"${mirror_name}\"} [${monitoring_period}])) <= ${critical_throughput}",
        for         => '3m',
        #severity    => 'critical'
        severity    => 'warning'
    }

    prometheus::alert::rule { "KmmAvgMsgProduceRateWarning-${mirror_name}":
        group       => 'KafkaMirrorMaker',
        alert_name  => 'KafkaMirrorMakerAvgMsgProduceRate',
        description => "Kafka MirrorMaker ${mirror_name} average message produce rate in last ${monitoring_period}",
        summary     => "Kafka MirrorMaker ${mirror_name} average message produce rate in last ${monitoring_period}",
        expr        => "sum(avg_over_time(kafka_producer_producer_metrics_record_send_rate{mirror_name=\"${mirror_name}\"} [${monitoring_period}])) <= ${warning_throughput}",
        for         => '3m',
        #severity    => 'warning'
        severity    => 'info'
    }

    prometheus::alert::rule { "KmmAvgMsgProduceRateCritical-${mirror_name}":
        group       => 'KafkaMirrorMaker',
        alert_name  => 'KafkaMirrorMakerAvgMsgProduceRate',
        description => "Kafka MirrorMaker ${mirror_name} average message produce rate in last ${monitoring_period}",
        summary     => "Kafka MirrorMaker ${mirror_name} average message produce rate in last ${monitoring_period}",
        expr        => "sum(avg_over_time(kafka_producer_producer_metrics_record_send_rate{mirror_name=\"${mirror_name}\"} [${monitoring_period}])) <= ${critical_throughput}",
        for         => '3m',
        #severity    => 'critical'
        severity    => 'warning'
    }

    # numDroppedMessages here doesn't really mean that messages were lost.
    # abort.on.send.failure defaults to true, so any MirrorMaker process that encounters
    # this will die before committing the offset for any dropped messages.  This will
    # cause these messages to be reconsumed and produced again by another MirrorMaker process.
    # https://github.com/apache/kafka/blob/trunk/core/src/main/scala/kafka/tools/MirrorMaker.scala#L741-L747
    # We alert on this, but are lenient about them.
    prometheus::alert::rule { "KmmDroppedMsgWarning-${mirror_name}":
        group       => 'KafkaMirrorMaker',
        alert_name  => 'KafkaMirrorMakerDroppedMsg',
        description => "Kafka MirrorMaker ${mirror_name} dropped message count in last ${monitoring_period}",
        summary     => "Kafka MirrorMaker ${mirror_name} dropped message count in last ${monitoring_period}",
        expr        => "sum(increase(kafka_tools_MirrorMaker_MirrorMaker_numDroppedMessages{mirror_name=\"${mirror_name}\"} [${monitoring_period}])) > 100",
        for         => '3m',
        #severity    => 'warning'
        severity    => 'info'
    }

    prometheus::alert::rule { "KmmDroppedMsgCritical-${mirror_name}":
        group       => 'KafkaMirrorMaker',
        alert_name  => 'KafkaMirrorMakerDroppedMsg',
        description => "Kafka MirrorMaker ${mirror_name} dropped message count in last ${monitoring_period}",
        summary     => "Kafka MirrorMaker ${mirror_name} dropped message count in last ${monitoring_period}",
        expr        => "sum(increase(kafka_tools_MirrorMaker_MirrorMaker_numDroppedMessages{mirror_name=\"${mirror_name}\"} [${monitoring_period}])) > 1000",
        for         => '3m',
        #severity    => 'critical'
        severity    => 'warning'
    }

    # Alert on max consumer lag in last $lag_check_period minutes.
    #
    # The change-prop topics are currently not replicated but due to previous tests,
    # the commits/offsets registered for those within the mirror maker consumer
    # group were not deleted from Kafka. They still end up in the Burrow's metrics
    # for the mirror maker consumer group, showing a constant lag that triggers the alarm.
    $lag_check_period = '10'

    if $topic_blacklist != undef {
        $cgroup_lag_query = "max(max_over_time(kafka_burrow_partition_lag{group=\"kafka-mirror-${mirror_name}\",topic!~\"${topic_blacklist}\"} [${lag_check_period}m]))"
    } else {
        $cgroup_lag_query = "max(max_over_time(kafka_burrow_partition_lag{group=\"kafka-mirror-${mirror_name}\"} [${lag_check_period}m]))"
    }

    $retries = 3
    $retry_interval = 10
    # This metric does not have the mirror_name label, so we target it in the group instead.
    prometheus::alert::rule { "KmmConsumerMaxLagWarning-${mirror_name}":
        group       => 'KafkaMirrorMaker',
        alert_name  => 'KafkaMirrorMakerConsumerMaxLag',
        description => "Kafka MirrorMaker ${mirror_name} max lag in last ${lag_check_period} minutes",
        summary     => "Kafka MirrorMaker ${mirror_name} max lag in last ${lag_check_period} minutes",
        expr        => "${cgroup_lag_query} > ${warning_lag}",
        for         => "${1 + (($retries - 1) * $retry_interval)}m",
        #severity    => 'warning',
        severity    => 'info',
        site        => $source_prometheus_site,
        instance    => $source_prometheus_instance,
    }

    prometheus::alert::rule { "KmmConsumerMaxLagCritical-${mirror_name}":
        group       => 'KafkaMirrorMaker',
        alert_name  => 'KafkaMirrorMakerConsumerMaxLag',
        description => "Kafka MirrorMaker ${mirror_name} max lag in last ${lag_check_period} minutes",
        summary     => "Kafka MirrorMaker ${mirror_name} max lag in last ${lag_check_period} minutes",
        expr        => "${cgroup_lag_query} > ${critical_lag}",
        for         => "${1 + (($retries - 1) * $retry_interval)}m",
        #severity    => 'critical',
        severity    => 'warning',
        site        => $source_prometheus_site,
        instance    => $source_prometheus_instance,
    }
}
