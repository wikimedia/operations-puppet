# == Define confluent::kafka::mirror::alerts
#
# == Parameters
#
# [*title*]
#   Should be the same as the confluent::kafka::mirror::instance you want
#   monitor.
#
# [*group_prefix*]
#   $group_prefix passed to confluent::kafka::mirror::jmxtrans. This will be
#   used for graphite based alerts.
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
