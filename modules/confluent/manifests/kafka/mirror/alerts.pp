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
#  [*contact_group*]
#       Defaults to admins, the nagios contact group for the service.
#
define confluent::kafka::mirror::alerts(
    $group_prefix        = undef,
    $contact_group       = hiera('contactgroups', 'admins'),
) {
    # Generate icinga alert if Kafka Server is not running.
    nrpe::monitor_service { "kafka-mirror-${title}":
        description   => "Kafka MirrorMaker ${title}",
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C java  --ereg-argument-array 'kafka.tools.MirrorMaker.+/etc/kafka/mirror/${title}/producer\\.properties'",
        contact_group => $contact_group,
        require       => Systemd::Service["kafka-mirror-${title}"],
    }
}
