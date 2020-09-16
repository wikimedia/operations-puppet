# Class profile::rsyslog::udp_localhost_compat - UDP syslog localhost compatiblity endpoint

# This class is meant to ease the transition for applications sending their logs to localhost.
# The preferred interface is sending syslog via UNIX socket /dev/log. This socket is managed by
# journald and syslog messages are forwarded to rsyslog as needed.

class profile::rsyslog::udp_localhost_compat (
    Array   $logging_kafka_brokers = hiera('profile::rsyslog::kafka_shipper::kafka_brokers'),
    Integer $port = hiera('profile::rsyslog::udp_localhost_compat_port', 10514),
    Array[String] $queue_enabled_sites = lookup('profile::rsyslog::kafka_queue_enabled_sites',
                                                {'default_value' => []}),
) {
    require_package('rsyslog-kafka')

    $queue_size = $::site in $queue_enabled_sites ? {
        true  => 10000,
        false => 0,
    }

    rsyslog::conf { 'udp_localhost_compat':
        content  => template('profile/rsyslog/udp_localhost_compat.conf.erb'),
        priority => 50,
    }
}
