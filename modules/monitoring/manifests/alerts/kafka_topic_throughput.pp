# Define: profile::kafka::alert::topic_throughput
# To be declared on monitoring host. This will alert if the message rate througput
# of a topic (or sum of topics) on a Kafka cluster exceed or drops from the given threshold.
#
# Parameters:
#
# [*kafka_cluster_name*]
#   Name of Kafka cluser in kafka_clusters hiera.
# [*topic*]
#   Topic (regex allowed) to check throughput of.  If multiple topics are matched, this will
#   check the sum of their message rate.
# [*warning*]
#   warning threshold
# [*critical*]
#   critical threshold
# [*method*]
#   Default: ge
# [*period*]
#   Default: 15m
# [*dashboard_links*]
#   Default: undef
# [*prometheus_url*]
#   Default: "http://prometheus.svc.${::site}.wmnet/ops",
# [*nagios_critical*]
#   Default: false
# [*contact_group*]
#   Default: admins
# [*ensure*]
#   Default: present
#
define monitoring::alerts::kafka_topic_throughput (
    $kafka_cluster_name,
    $topic,
    $warning,
    $critical,
    $method                 = 'ge',
    $period                 = '15m',
    $dashboard_links        = undef,
    $prometheus_url         = "http://prometheus.svc.${::site}.wmnet/ops",
    $nagios_critical        = false,
    $contact_group          = 'admins',
    Wmflib::Ensure $ensure  = present,
) {
    # Alert if the message rate for the matched topics is outside of the given threshold.
    monitoring::check_prometheus { "kafka_topic_throughput_${title}":
        ensure          => $ensure,
        description     => "Kafka topic throughput alert for ${title} in cluster ${kafka_cluster_name} for topic(s) ${topic}.  Message rate should be ${method} (${warning}, ${critical}).",
        dashboard_links => $dashboard_links,
        # Examine the rate in the $quantile percentile over the last $period.
        query           => "scalar(sum(rate(kafka_server_BrokerTopicMetrics_MessagesIn_total{kafka_cluster=\"${kafka_cluster_name}\",topic=~\"${topic}\"}[${period}])))",
        method          => $method,
        warning         => $warning,
        critical        => $critical,
        prometheus_url  => $prometheus_url,
        nagios_critical => $nagios_critical,
        contact_group   => $contact_group,
    }
}
