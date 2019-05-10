# == Define burrow::check_consumer_lag
#
# Installs an nrpe check for Kafka consumer lag on a single consumer group
# in a Kafka cluster.
#
# == Parameters
#
#   [*title*]
#       Kafka consumer group name to check
#
#   [*burrow_uri*]
#       Default: http://localhost:8100
#
#   [*lag_threshold*]
#       Critical threshold for consumer group lag.  Default 1000
#
#   [*contact_group*]
#       Default: admins
#
#   [*critical*]
#       Default: false
#
define burrow::check_consumer_lag(
    $kafka_cluster_name,
    $burrow_uri             = 'http://localhost:8100',
    $lag_threshold          = 1000,
    $contact_group          = 'admins',
    $critical               = false,
) {
    $consumer_group = $title

    if !defined(File['/usr/local/lib/nagios/plugins/check_kafka_consumer_lag']) {
        file { '/usr/local/lib/nagios/plugins/check_kafka_consumer_lag':
            source => 'puppet:///modules/burrow/check_kafka_consumer_lag.py',
            mode   => '0555',
        }
    }

    nrpe::monitor_service { "${kafka_cluster_name}_${consumer_group}_consumer_lag":
        description    => "Kafka ${kafka_cluster_name} consumer group lag for ${consumer_group}",
        nrpe_command   => "/usr/local/lib/nagios/plugins/check_kafka_consumer_lag --base-url ${burrow_uri} --kafka-cluster ${kafka_cluster_name} --consumer-group ${consumer_group} --critical-lag ${lag_threshold}",
        contact_group  => $contact_group,
        critical       => $critical,
        # Only alert if lag remains present for 3 checks in 10 minute intervals, i.e. 30 minutes.
        retries        => 3,
        retry_interval => 10,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/EventLogging/Administration#Consumption_Lag_%22Alarms%22:_Burrow',
    }
}
