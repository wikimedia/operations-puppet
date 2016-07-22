# == Define confluent::kafka::mirror::monitoring
#
# == Parameters
# $title               - Should be the same as the kafka::mirror instance
#                        you want.
#                        to monitor.
# $group_prefix        - $group_prefix passed to kafka::mirror::jmxtrans.
#                        This will be used for graphite based alerts.
#                        Default: undef
#
define confluent::kafka::mirror::alerts(
    $group_prefix        = undef,
) {
    # Generate icinga alert if Kafka Server is not running.
    nrpe::monitor_service { "kafka-mirror-${title}":
        description  => "Kafka MirrorMaker ${title}",
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C java  --ereg-argument-array 'kafka.tools.MirrorMaker.+/etc/kafka/mirror/${title}/producer\.properties'",
        require      => Confluent::Kafka::Mirror[$title],
    }
}
